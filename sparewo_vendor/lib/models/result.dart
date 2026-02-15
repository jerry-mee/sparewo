// lib/models/result.dart

import 'package:meta/meta.dart';

@immutable
abstract class Result<State> {
  const Result();

  factory Result.data(State state) = ResultData<State>;

  factory Result.error(Object error, StackTrace stackTrace) =
      ResultError<State>;

  static Result<State> guard<State>(State Function() cb) {
    try {
      return Result.data(cb());
    } catch (err, stack) {
      return Result.error(err, stack);
    }
  }

  bool get hasState;
  State? get stateOrNull;
  State get requireState;

  R map<R>({
    required R Function(ResultData<State> data) data,
    required R Function(ResultError<State> error) error,
  });

  R when<R>({
    required R Function(State data) data,
    required R Function(Object error, StackTrace stackTrace) error,
  });
}

@internal
class ResultData<State> extends Result<State> {
  final State state;

  const ResultData(this.state);

  @override
  bool get hasState => true;

  @override
  State? get stateOrNull => state;

  @override
  State get requireState => state;

  @override
  R map<R>({
    required R Function(ResultData<State> data) data,
    required R Function(ResultError<State> error) error,
  }) {
    return data(this);
  }

  @override
  R when<R>({
    required R Function(State data) data,
    required R Function(Object error, StackTrace stackTrace) error,
  }) {
    return data(state);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultData<State> &&
          runtimeType == other.runtimeType &&
          state == other.state;

  @override
  int get hashCode => state.hashCode;
}

@internal
class ResultError<State> extends Result<State> {
  final Object error;
  final StackTrace stackTrace;

  const ResultError(this.error, this.stackTrace);

  @override
  bool get hasState => false;

  @override
  State? get stateOrNull => null;

  @override
  State get requireState => Error.throwWithStackTrace(error, stackTrace);

  @override
  R map<R>({
    required R Function(ResultData<State> data) data,
    required R Function(ResultError<State> error) error,
  }) {
    return error(this);
  }

  @override
  R when<R>({
    required R Function(State data) data,
    required R Function(Object error, StackTrace stackTrace) error,
  }) {
    return error(this.error, stackTrace);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultError<State> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(error, stackTrace);
}
