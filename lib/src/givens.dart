import 'package:meta/meta.dart';

import 'core.dart';
import 'search_strategy/pair.dart';
import 'search_strategy/strategies.dart';
import 'settings.dart';

extension AndPair<T> on SearchStrategy<T> {
  SearchStrategy<(T, U)> and<U>(SearchStrategy<U> other) =>
      PairStrategy(this, other);
}

class Given1<T1> extends Given<T1> {
  Given1(SearchStrategy<T1> strategy1, {Settings? settings, Object? seed})
    : super(strategy1, settings ?? Settings.defaultValue, seed);

  @isTest
  void test1(Object? description, void Function(T1) testFunction) =>
      super.test(description, (T1 ts) => testFunction(ts));
}

class Given2<T1, T2> extends Given<(T1, T2)> {
  Given2(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2, {
    Settings? settings,
    Object? seed,
  }) : super(strategy1.and(strategy2), settings ?? Settings.defaultValue, seed);

  @isTest
  void test2(Object? description, void Function(T1, T2) testFunction) =>
      super.test(description, ((T1, T2) ts) => testFunction(ts.$1, ts.$2));
}

class Given3<T1, T2, T3> extends Given<(T1, (T2, T3))> {
  Given3(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(strategy2.and(strategy3)),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test3(Object? description, void Function(T1, T2, T3) testFunction) =>
      super.test(
        description,
        ((T1, (T2, T3)) ts) => testFunction(ts.$1, ts.$2.$1, ts.$2.$2),
      );
}

class Given4<T1, T2, T3, T4> extends Given<(T1, (T2, (T3, T4)))> {
  Given4(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3,
    SearchStrategy<T4> strategy4, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(strategy2.and(strategy3.and(strategy4))),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test4(Object? description, void Function(T1, T2, T3, T4) testFunction) =>
      super.test(
        description,
        ((T1, (T2, (T3, T4))) ts) =>
            testFunction(ts.$1, ts.$2.$1, ts.$2.$2.$1, ts.$2.$2.$2),
      );
}

class Given5<T1, T2, T3, T4, T5> extends Given<(T1, (T2, (T3, (T4, T5))))> {
  Given5(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3,
    SearchStrategy<T4> strategy4,
    SearchStrategy<T5> strategy5, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(strategy2.and(strategy3.and(strategy4.and(strategy5)))),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test5(
    Object? description,
    void Function(T1, T2, T3, T4, T5) testFunction,
  ) => super.test(
    description,
    ((T1, (T2, (T3, (T4, T5)))) ts) => testFunction(
      ts.$1,
      ts.$2.$1,
      ts.$2.$2.$1,
      ts.$2.$2.$2.$1,
      ts.$2.$2.$2.$2,
    ),
  );
}

class Given6<T1, T2, T3, T4, T5, T6>
    extends Given<(T1, (T2, (T3, (T4, (T5, T6)))))> {
  Given6(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3,
    SearchStrategy<T4> strategy4,
    SearchStrategy<T5> strategy5,
    SearchStrategy<T6> strategy6, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(
           strategy2.and(
             strategy3.and(strategy4.and(strategy5.and(strategy6))),
           ),
         ),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test6(
    Object? description,
    void Function(T1, T2, T3, T4, T5, T6) testFunction,
  ) => super.test(
    description,
    ((T1, (T2, (T3, (T4, (T5, T6))))) ts) => testFunction(
      ts.$1,
      ts.$2.$1,
      ts.$2.$2.$1,
      ts.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2,
    ),
  );
}

class Given7<T1, T2, T3, T4, T5, T6, T7>
    extends Given<(T1, (T2, (T3, (T4, (T5, (T6, T7))))))> {
  Given7(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3,
    SearchStrategy<T4> strategy4,
    SearchStrategy<T5> strategy5,
    SearchStrategy<T6> strategy6,
    SearchStrategy<T7> strategy7, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(
           strategy2.and(
             strategy3.and(
               strategy4.and(strategy5.and(strategy6.and(strategy7))),
             ),
           ),
         ),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test7(
    Object? description,
    void Function(T1, T2, T3, T4, T5, T6, T7) testFunction,
  ) => super.test(
    description,
    ((T1, (T2, (T3, (T4, (T5, (T6, T7)))))) ts) => testFunction(
      ts.$1,
      ts.$2.$1,
      ts.$2.$2.$1,
      ts.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2.$2,
    ),
  );
}

class Given8<T1, T2, T3, T4, T5, T6, T7, T8>
    extends Given<(T1, (T2, (T3, (T4, (T5, (T6, (T7, T8)))))))> {
  Given8(
    SearchStrategy<T1> strategy1,
    SearchStrategy<T2> strategy2,
    SearchStrategy<T3> strategy3,
    SearchStrategy<T4> strategy4,
    SearchStrategy<T5> strategy5,
    SearchStrategy<T6> strategy6,
    SearchStrategy<T7> strategy7,
    SearchStrategy<T8> strategy8, {
    Settings? settings,
    Object? seed,
  }) : super(
         strategy1.and(
           strategy2.and(
             strategy3.and(
               strategy4.and(
                 strategy5.and(strategy6.and(strategy7.and(strategy8))),
               ),
             ),
           ),
         ),
         settings ?? Settings.defaultValue,
         seed,
       );

  @isTest
  void test8(
    Object? description,
    void Function(T1, T2, T3, T4, T5, T6, T7, T8) testFunction,
  ) => super.test(
    description,
    ((T1, (T2, (T3, (T4, (T5, (T6, (T7, T8))))))) ts) => testFunction(
      ts.$1,
      ts.$2.$1,
      ts.$2.$2.$1,
      ts.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2.$2.$1,
      ts.$2.$2.$2.$2.$2.$2.$2,
    ),
  );
}
