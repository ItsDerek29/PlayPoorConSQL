import 'package:equatable/equatable.dart';


abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<dynamic> get props => [];
}

class RemoveLastItemEvent extends PlayerEvent {
  const RemoveLastItemEvent();
}