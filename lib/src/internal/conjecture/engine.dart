import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'minimizer.dart';

import '../../dart_utils/bytes.dart';
import '../../dart_utils/context_manager.dart';
import '../../dart_utils/counter.dart';
import '../../hypothesis_random.dart';
import '../../reporting.dart';
import '../../settings.dart';
import '../intervalsets.dart';
import 'data.dart';

int currentMillis() => DateTime.timestamp().millisecondsSinceEpoch;

class RunIsComplete implements Exception {
  RunIsComplete();
}

class TestRunner {
  void Function(TestData) _testFunction;
  Settings settings;
  TestData? lastData;
  int changed = 0;
  int shrinks = 0;
  int examplesConsidered = 0;
  int iterations = 0;
  int validExamples = 0;
  int startTime = currentMillis();
  HypothesisRandom random;
  Bytes? databaseKey;

  TestRunner._(
    this._testFunction,
    this.settings,
    this.random,
    this.databaseKey,
  );

  factory TestRunner(
    void Function(TestData) testFunction, {
    Settings? settings,
    HypothesisRandom? random,
    Bytes? databaseKey,
  }) => TestRunner._(
    testFunction,
    settings ?? Settings(),
    random ?? BetterHypRandom(Random().nextInt(1 << 32)),
    databaseKey,
  );

  void newBuffer() {
    lastData = TestData(
      settings.bufferSize,
      (TestData data, int n, Distribution distribution) =>
          distribution(random!, n),
    );
    testFunction(lastData!);
    lastData!.freeze();
    noteForCorpus(lastData!);
  }

  void testFunction(TestData data) {
    iterations += 1;
    try {
      _testFunction(data);
      data.freeze();
    } on StopTest catch (st) {
      if (st.testCounter != data.testCounter) {
        saveBuffer(data.buffer);
        rethrow;
      }
    } on Exception {
      saveBuffer(data.buffer);
      rethrow;
    }
    if (data.status >= Status.valid) {
      validExamples += 1;
    }
  }

  bool considerNewTestData(TestData data) {
    // Transition rules:
    //   1. Transition cannot decrease the status
    //   2. Any transition which increases the status is valid
    //   3. If the previous status was interesting, only shrinking
    //      transitions are allowed.
    assert(lastData != null);
    if (lastData!.status < data.status) {
      return true;
    }
    if (lastData!.status > data.status) {
      return false;
    }
    if (data.status == .invalid) {
      return data.index >= lastData!.index;
    }
    if (data.status == .overrun) {
      return data.overdraw <= lastData!.overdraw;
    }
    if (data.status == .interesting) {
      assert(data.buffer.length <= lastData!.buffer.length);
      if (data.buffer.length == lastData!.buffer.length) {
        assert(data.buffer < lastData!.buffer);
      }
      return true;
    }
    return true;
  }

  void saveBuffer(Bytes buffer) {
    if (databaseKey != null) {
      settings.database!.save(databaseKey!, buffer);
    }
  }

  void noteForCorpus(TestData data) {
    if (data.status == .interesting) {
      saveBuffer(data.buffer);
    }
  }

  void debug(String message) {
    debugReport(message);
  }

  void debugData(TestData data) {
    debug(
      "${data.index} bytes ${data.buffer.sublist(0, data.index)} -> ${data.status.name} ${data.output}",
    );
  }

  bool incorporateNewBuffer(Bytes buffer) {
    assert(lastData!.status == .interesting);
    if (settings.timeout > 0 &&
        currentMillis() >= startTime + settings.timeout) {
      throw RunIsComplete();
    }
    examplesConsidered += 1;
    buffer = buffer.sublist(0, lastData!.index);
    if (compareSortKeys(sortKey(buffer), sortKey(lastData!.buffer)) >= 0) {
      return false;
    }
    assert(compareSortKeys(sortKey(buffer), sortKey(lastData!.buffer)) <= 0);
    TestData data = TestData.forBuffer(buffer);
    testFunction(data);
    data.freeze();
    noteForCorpus(data);
    if (data.status >= lastData!.status) {
      debugData(data);
    }
    if (considerNewTestData(data)) {
      shrinks += 1;
      lastData = data;
      if (shrinks >= settings.maxShrinks) {
        throw RunIsComplete();
      }
      lastData = data;
      changed += 1;
      return true;
    }
    return false;
  }

  void run() {
    using(settings, (Settings settings) {
      try {
        _run();
      } on RunIsComplete {
        // do nothing
      }
      debug(
        "Run complete after $iterations examples "
        "($validExamples valid) and $shrinks shrinks",
      );
    });
  }

  Bytes Function(TestData, int, Distribution) _newMutator() {
    Bytes drawNew(TestData data, int n, Distribution distribution) =>
        distribution(random!, n);

    Bytes drawExisting(TestData data, int n, Distribution distribution) =>
        lastData!.buffer.sublist(data.index, data.index + n);

    Bytes drawSmaller(TestData data, int n, Distribution distribution) {
      Bytes existing = lastData!.buffer.sublist(data.index, data.index + n);
      Bytes r = distribution(random!, n);
      if (r <= existing) {
        return r;
      }
      return _drawPredecessor(random!, existing);
    }

    Bytes drawLarger(TestData data, int n, Distribution distribution) {
      Bytes existing = lastData!.buffer.sublist(data.index, data.index + n);
      Bytes r = distribution(random!, n);
      if (r >= existing) {
        return r;
      }
      return _drawSuccessor(random!, existing);
    }

    Bytes reuseExisting(TestData data, int n, Distribution distribution) {
      List<int> choices = data.blockStarts[n] ?? [];
      if (choices.isEmpty) {
        choices = lastData!.blockStarts[n] ?? [];
      }
      if (choices.isNotEmpty) {
        int i = random!.choice(choices);
        return lastData!.buffer.sublist(i, i + n);
      } else {
        return distribution(random!, n);
      }
    }

    Bytes flipBit(TestData data, int n, Distribution distribution) {
      Bytes buf = lastData!.buffer.sublist(data.index, data.index + n);
      int i = random!.randInt(0, n - 1);
      int k = random!.randInt(0, 7);
      buf.wrapped[i] = buf.wrapped[i] ^ (1 << k);
      return buf;
    }

    Bytes drawZero(TestData data, int n, Distribution distribution) {
      return Bytes(Uint8List(n));
    }

    Bytes drawConstant(TestData data, int n, Distribution distribution) {
      int c = random!.randInt(0, 255);
      return Bytes(Uint8List.fromList(List.generate(n, (_) => c)));
    }

    List<Bytes Function(TestData, int, Distribution)> options = [
      drawNew,
      reuseExisting,
      reuseExisting,
      drawExisting,
      drawSmaller,
      drawLarger,
      flipBit,
      drawZero,
      drawConstant,
    ];

    List<Bytes Function(TestData, int, Distribution)> bits = List.generate(
      4,
      (_) => random!.choice(options),
    );

    Bytes drawMutated(TestData data, int n, Distribution distribution) {
      if (data.index + n > lastData!.buffer.length) {
        return distribution(random!, n);
      }
      return random!.choice(bits)(data, n, distribution);
    }

    return drawMutated;
  }

  void _run() {
    lastData = null;
    int mutations = 0;
    int startTimeInMillis = currentMillis();

    if (databaseKey != null) {
      List<Bytes> corpus = settings.database!
          .fetch(databaseKey!)
          .sortedBy((bs) => bs.length);
      for (Bytes existing in corpus) {
        if (validExamples >= settings.maxExamples) {
          return;
        }
        if (iterations >= max(settings.maxIterations, settings.maxExamples)) {
          return;
        }
        TestData data = TestData.forBuffer(existing);
        testFunction(data);
        data.freeze();
        lastData = data;
        if (data.status >= .valid) {
          settings.database!.delete(databaseKey!, existing);
        } else if (data.status == .valid) {
          // Incremental garbage collection! we store a lot of
          // examples in the DB as we shrink: Those that stay
          // interesting get kept, those that become invalid get
          // dropped, but those that are merely valid gradually go
          // away over time.
          if (random!.randInt(0, 2) == 0) {
            settings.database!.delete(databaseKey!, existing);
          }
        } else {
          assert(data.status == .interesting);
          lastData = data;
          break;
        }
      }
    }

    if (lastData == null || lastData!.status <= .interesting) {
      newBuffer();
    }
    var mutator = _newMutator();
    while (lastData!.status != .interesting) {
      if (validExamples > settings.maxExamples) {
        return;
      }
      if (iterations > max(settings.maxIterations, settings.maxExamples)) {
        return;
      }
      if (settings.timeout > 0 &&
          currentMillis() >= startTimeInMillis + settings.timeout) {
        return;
      }
      if (mutations >= settings.maxMutations) {
        mutations = 0;
        newBuffer();
        mutator = _newMutator();
      } else {
        TestData data = TestData(settings.bufferSize, mutator);
        testFunction(data);
        data.freeze();
        noteForCorpus(data);
        TestData prevData = lastData!;
        if (considerNewTestData(data)) {
          lastData = data;
          if (data.status > prevData.status) {
            mutations = 0;
          }
        }
      }
      mutations += 1;
    }
    TestData data = lastData!;
    debugData(data);
    if (settings.maxShrinks <= 0) {
      return;
    }

    data = TestData.forBuffer(lastData!.buffer);
    testFunction(data);
    if (data.status != .interesting) {
      return;
    }

    int changeCounter = -1;

    while (changed > changeCounter) {
      changeCounter = changed;
      int i = 0;
      while (i < lastData!.intervals.length) {
        Interval uv = lastData!.intervals[i];
        if (!incorporateNewBuffer(
          lastData!.buffer
              .sublist(0, uv.start)
              .followedBy(lastData!.buffer.sublist(uv.end)),
        )) {
          i += 1;
        }
      }
      i = 0;
      while (i < lastData!.blocks.length) {
        Interval uv = lastData!.blocks[i];
        Bytes buffer = lastData!.buffer;
        Bytes block = buffer.sublist(uv.start, uv.end);
        int n = uv.end - uv.start;
        List<int> as = lastData!.blockStarts[n]!;
        Iterable<Bytes> buffers = as.map((a) => buffer.sublist(a, a + n));
        List<Bytes> allBlocks = buffers
            .fold([
              Bytes(Uint8List.fromList([n])),
            ], (Iterable<Bytes> acc, Bytes next) => acc.followedBy([next]))
            .toSet()
            .sorted();
        List<Bytes> betterBlocks = allBlocks.sublist(
          0,
          allBlocks.indexOf(block),
        );
        for (Bytes b in betterBlocks) {
          if (incorporateNewBuffer(
            buffer
                .sublist(0, uv.start)
                .followedBy(b)
                .followedBy(buffer.sublist(uv.end)),
          )) {
            break;
          }
        }
        i += 1;
      }

      int blockCounter = -1;
      while (blockCounter < changed) {
        blockCounter = changed;
        Counter<Bytes> counter = Counter(
          lastData!.blocks.map(
            (Interval uv) => lastData!.buffer.sublist(uv.start, uv.end),
          ),
        );
        List<Bytes> blocks = counter.entries
            .where((MapEntry<Bytes, int> kv) => kv.value > 1)
            .map((kv) => kv.key)
            .toList();
        for (Bytes block in blocks) {
          var parts = lastData!.buffer.split(block);
          minimize(
            block,
            (Bytes b) => incorporateNewBuffer(parts.glue(b)),
            random: random,
          );
        }
      }

      i = 0;
      while (i < lastData!.blocks.length) {
        Interval uv = lastData!.blocks[i];
        minimize(
          lastData!.buffer.sublist(uv.start, uv.end),
          (Bytes b) => incorporateNewBuffer(
            lastData!.buffer
                .sublist(0, uv.start)
                .followedBy(b)
                .followedBy(lastData!.buffer.sublist(uv.end)),
          ),
          random: random,
        );
        i += 1;
      }

      i = 0;
      List<Bytes>? alternatives;
      while (i < lastData!.intervals.length) {
        alternatives ??= lastData!.intervals
            .map((Interval uv) => lastData!.buffer.sublist(uv.start, uv.end))
            .toSet()
            .sortedBy((Bytes b) => b.length)
            .toList();
        Interval uv = lastData!.intervals[i];
        for (Bytes a in alternatives) {
          Bytes buf = lastData!.buffer;
          if (a.length < uv.end - uv.start ||
              (a.length == (uv.end - uv.start) &&
                  a < buf.sublist(uv.start, uv.end))) {
            if (incorporateNewBuffer(
              buf
                  .sublist(0, uv.start)
                  .followedBy(a)
                  .followedBy(buf.sublist(uv.end)),
            )) {
              alternatives = null;
              break;
            }
          }
        }
        i += 1;
      }
    }
  }
}

Bytes _drawPredecessor(HypothesisRandom rnd, Bytes xs) {
  Uint8List r = Uint8List(0);
  bool anyStrict = false;
  for (int x in xs.wrapped) {
    int c;
    if (!anyStrict) {
      c = rnd.randInt(0, x);
      if (c < x) {
        anyStrict = true;
      }
    } else {
      c = rnd.randInt(0, 255);
    }
    r.add(c);
  }
  return Bytes(r);
}

Bytes _drawSuccessor(HypothesisRandom rnd, Bytes xs) {
  Uint8List r = Uint8List(0);
  bool anyStrict = false;
  for (int x in xs.wrapped) {
    int c;
    if (!anyStrict) {
      c = rnd.randInt(x, 255);
      if (c > x) {
        anyStrict = true;
      }
    } else {
      c = rnd.randInt(0, 255);
    }
    r.add(c);
  }
  return Bytes(r);
}

(int, Bytes) sortKey(Bytes buffer) => (buffer.length, buffer);

int compareSortKeys((int, Bytes) sk1, (int, Bytes) sk2) {
  int lengthCmp = sk1.$1 - sk2.$1;
  if (lengthCmp != 0) {
    return lengthCmp;
  } else {
    return sk1.$2.compareTo(sk2.$2);
  }
}

extension Split on Bytes {
  List<Bytes> split(Bytes sep) {
    assert(sep.isNotEmpty); // otherwise, will never complete
    List<Bytes> parts = [];
    int i = 0;
    int index = indexOfSublist(sep, i);
    while (index != -1) {
      parts.add(sublist(i, index));
      i = index + sep.length;
      index = indexOfSublist(sep, i);
    }
    return parts;
  }

  int indexOfSublist(Bytes sublist, int start) {
    if (sublist.isEmpty) {
      return 0;
    } else if (start + sublist.length > length) {
      return -1;
    }

    for (int i = start; i <= length - sublist.length; i++) {
      bool isMatch = true;
      for (int j = 0; j < sublist.length; j++) {
        if (this[i + j] != sublist[j]) {
          isMatch = false;
          break;
        }
      }
      if (isMatch) {
        return i;
      }
    }
    return -1;
  }
}

extension Glue on List<Bytes> {
  Bytes glue(Bytes sep) {
    Iterable<Uint8List> wrappedLists = map((b) => b.wrapped);
    BytesBuilder bb = BytesBuilder();
    bb.add(wrappedLists.first);
    for (Uint8List wb in wrappedLists) {
      bb.add(sep.wrapped);
      bb.add(wb);
    }
    return Bytes(bb.toBytes());
  }
}
