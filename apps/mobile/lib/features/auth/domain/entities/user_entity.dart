import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.emailVerified = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final bool emailVerified;

  @override
  List<Object?> get props => [id, email, displayName, avatarUrl, emailVerified];
}
