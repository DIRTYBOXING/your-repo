import '../models/event_model.dart';

/// V12 STATE MACHINE: EVENTS
sealed class EventState {}

class EventInitial extends EventState {}

class EventLoading extends EventState {}

class EventLoaded extends EventState {
  final List<EventModel> events;
  EventLoaded(this.events);
}

class EventError extends EventState {
  final String message;
  EventError(this.message);
}
