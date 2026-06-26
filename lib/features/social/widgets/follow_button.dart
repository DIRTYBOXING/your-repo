import 'package:flutter/material.dart';
import '../../../shared/services/social_service.dart';

/// Follow / Unfollow button backed by Firestore (SocialService).
class FollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final ValueChanged<bool>? onChanged;
  final bool compact;

  const FollowButton({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    this.onChanged,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _loading = true;
  bool _busy = false;

  final _social = SocialService();

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final result = await _social.isFollowing(
        widget.currentUserId,
        widget.targetUserId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_busy) return;
    if (widget.currentUserId == widget.targetUserId) return;
    setState(() => _busy = true);
    try {
      if (_isFollowing) {
        await _social.unfollowUser(widget.currentUserId, widget.targetUserId);
      } else {
        await _social.followUser(widget.currentUserId, widget.targetUserId);
      }
      if (mounted) {
        final nextState = !_isFollowing;
        setState(() => _isFollowing = nextState);
        widget.onChanged?.call(nextState);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Follow action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.compact ? 32.0 : 36.0;
    final spinnerSize = widget.compact ? 16.0 : 18.0;
    final horizontalPadding = widget.compact ? 12.0 : 20.0;
    final verticalPadding = widget.compact ? 6.0 : 8.0;

    if (_loading) {
      return SizedBox(
        width: widget.compact ? 82 : 90,
        height: buttonHeight,
        child: Center(
          child: SizedBox(
            width: spinnerSize,
            height: spinnerSize,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.amber,
            ),
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: _busy ? null : _toggleFollow,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.grey : Colors.amber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        minimumSize: Size(widget.compact ? 0 : 90, buttonHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: _busy
          ? SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black54,
              ),
            )
          : Text(
              _isFollowing ? 'Following' : 'Follow',
              style: TextStyle(fontSize: widget.compact ? 12 : 14),
            ),
    );
  }
}
