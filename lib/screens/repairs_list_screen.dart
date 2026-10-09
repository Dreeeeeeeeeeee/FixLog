import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../widgets/app_drawer.dart';
import 'add_repair_screen.dart';
import 'repair_details_screen.dart';
import '../widgets/repairs_filter_sheet.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/app_fab.dart';
import '../services/repair_service.dart';

class RepairsListScreen extends StatefulWidget {
  const RepairsListScreen({super.key});

  @override
  State<RepairsListScreen> createState() => _RepairsListScreenState();
}

class _RepairsListScreenState extends State<RepairsListScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = const ['All', 'Pending', 'Diagnosing', 'In Progress'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  RepairFilters _advancedFilters = RepairFilters(statuses: {...RepairStatus.values});

  List<Repair> _applyFilters(List<Repair> repairs) {
    return repairs.where((r) {
      final matchesChip = _activeFilter == 'All' || r.status.label == _activeFilter;
      final matchesAdvancedStatus = _advancedFilters.statuses.contains(r.status);
      final matchesDevice = _advancedFilters.deviceType == 'All Devices' ||
          r.deviceName == _advancedFilters.deviceType;
      final matchesSearch = _searchQuery.isEmpty ||
          r.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.deviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesChip && matchesAdvancedStatus && matchesDevice && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final result = await showRepairFilterSheet(context, initialFilters: _advancedFilters);
    if (result != null) {
      if (!mounted) return;
      await showLoadingOverlay(context, message: 'Applying filters...');
      if (!mounted) return;
      setState(() => _advancedFilters = result);
    }
  }

  Future<void> _simulateRefresh() async {
    // Hook up a real data refresh (API call / local DB re-query) here.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const AppDrawer(activeItem: DrawerItem.repairs),
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        title: const Text(
          'Repairs',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Search & Filter',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSearchField(),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _buildFilterChip(_filters[index]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Repair>>(
                stream: RepairService.instance.watchAll(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Something went wrong loading repairs.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.greyText, fontSize: 13),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    );
                  }

                  final filtered = _applyFilters(snapshot.data!);

                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _simulateRefresh,
                          color: AppColors.primaryBlue,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                _buildRepairCard(filtered[index]),
                          ),
                        );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFab(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddRepairScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 14, color: AppColors.darkText),
        decoration: InputDecoration(
          hintText: 'Search by customer, device, or ID...',
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.greyText, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.greyText, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.inputBorder, size: 64),
            const SizedBox(height: 16),
            Text(
              'No repairs found',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filter',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddRepairScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Add Repair', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool active = label == _activeFilter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primaryBlue : AppColors.inputBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.greyText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRepairCard(Repair repair) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RepairDetailsScreen(repair: repair)),
        );
      },
      child: Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(repair.icon, color: AppColors.greyText, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${repair.deviceName} ${repair.id}',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  repair.customerName,
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: repair.status),
              if (repair.date != null) ...[
                const SizedBox(height: 6),
                Text(
                  repair.date!,
                  style: TextStyle(color: AppColors.greyText, fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
