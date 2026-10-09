import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/loading_overlay.dart';
import 'add_technician_screen.dart';

class ManageTechniciansScreen extends StatelessWidget {
  const ManageTechniciansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Technicians',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: UserService.instance.isCurrentUserAdmin(),
          builder: (context, adminSnapshot) {
            if (!adminSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              );
            }
            if (adminSnapshot.data != true) {
              return const _AccessDenied();
            }
            return const _TechnicianList();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTechnicianScreen()),
          );
        },
        child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.white),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.inputBorder, size: 64),
            SizedBox(height: 12),
            Text(
              'Admin access required',
              style: TextStyle(
                  color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Only admin accounts can add or manage technician logins.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianList extends StatelessWidget {
  const _TechnicianList();

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.instance.currentUser?.uid;

    return StreamBuilder<List<TechnicianProfile>>(
      stream: UserService.instance.watchAllTechnicians(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }
        final people = snapshot.data!;
        if (people.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No technician accounts yet.\nTap + to add the first one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.greyText, fontSize: 13),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          itemCount: people.length,
          itemBuilder: (context, index) => _buildTile(
            context,
            people[index],
            isMe: people[index].uid == myUid,
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context, TechnicianProfile person) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Remove ${person.name}?',
      message:
          "This removes their profile from FixLog and revokes admin access if they have it. "
          "Their login will still work unless you also disable it in the Firebase Console "
          "under Authentication → Users.",
      confirmLabel: 'Remove',
      icon: Icons.person_remove_rounded,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await showLoadingOverlay(
        context,
        message: 'Removing technician...',
        future: UserService.instance.deleteProfile(person.uid),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${person.name} was removed.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  Widget _buildTile(BuildContext context, TechnicianProfile person, {required bool isMe}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: person.isAdmin ? AppColors.statPurpleBg : AppColors.statBlueBg,
            child: Icon(
              person.isAdmin ? Icons.shield_outlined : Icons.person_outline_rounded,
              color: person.isAdmin ? AppColors.statPurple : AppColors.statBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text('(you)',
                          style: TextStyle(color: AppColors.greyText, fontSize: 12)),
                    ],
                  ],
                ),
                Text(
                  person.email,
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                if (person.username != null && person.username!.isNotEmpty)
                  Text(
                    '@${person.username}',
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: person.isAdmin ? AppColors.statPurpleBg : AppColors.statBlueBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              person.role,
              style: TextStyle(
                color: person.isAdmin ? AppColors.statPurple : AppColors.statBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.person_remove_outlined, color: AppColors.statRed, size: 20),
              tooltip: 'Remove technician',
              onPressed: () => _confirmRemove(context, person),
            ),
          ],
        ],
      ),
    );
  }
}