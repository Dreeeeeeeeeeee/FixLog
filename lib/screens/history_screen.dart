import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/activity_service.dart';
import '../services/repair_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_fab.dart';
import 'repair_details_screen.dart';
import 'add_repair_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  // "Deleted" is an event type rather than a repair status, so it gets
  // its own chip alongside the statuses.
  static const String _deletedFilter = 'Deleted';
  final List<String> _filters = [
    'All',
    ...RepairStatus.values.map((s) => s.label),
    _deletedFilter,
  ];

  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityEvent> _applyFilters(List<ActivityEvent> events) {
    final q = _searchQuery.toLowerCase();
    return events.where((e) {
      final isDeleted = e.type == ActivityType.deleted;
      final matchesChip = _activeFilter == 'All' ||
          (_activeFilter == _deletedFilter
              ? isDeleted
              : !isDeleted && e.status?.label == _activeFilter);
      final matchesSearch = q.isEmpty ||
          e.customerName.toLowerCase().contains(q) ||
          e.deviceName.toLowerCase().contains(q) ||
          e.ticketNumber.toLowerCase().contains(q);
      final matchesDateRange = _dateFrom == null ||
          _dateTo == null ||
          e.createdAt == null ||
          (!e.createdAt!.isBefore(_dateFrom!) &&
              !e.createdAt!.isAfter(_dateTo!.add(const Duration(days: 1))));
      return matchesChip && matchesSearch && matchesDateRange;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range != null) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
      });
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $hour12:$minute $period';
  }

  Future<void> _openEvent(ActivityEvent e) async {
    if (e.type == ActivityType.deleted || e.repairDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This repair has been deleted.')),
      );
      return;
    }
    final repair = await RepairService.instance.watchOne(e.repairDocId!).first;
    if (!mounted) return;
    if (repair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This repair has been deleted.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RepairDetailsScreen(repair: repair)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const AppDrawer(activeItem: DrawerItem.history),
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        title: const Text(
          'FixLog',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.statBlueBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.history_rounded,
                        color: AppColors.primaryBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            color: AppColors.darkText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'View the complete history of all repair activities.',
                          style: TextStyle(color: AppColors.greyText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final f in _filters) ...[
                    _buildFilterChip(f),
                    const SizedBox(width: 8),
                  ],
                  _buildDateRangeButton(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<ActivityEvent>>(
                stream: ActivityService.instance.watchRecent(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load history.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.greyText, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    );
                  }
                  final filtered = _applyFilters(snapshot.data!);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No activity found.\nNew repairs and status changes will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.greyText, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildEventCard(filtered[index]),
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
          hintText: 'Search by customer, device, or repair ID...',
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.greyText, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDateRangeButton() {
    final bool active = _dateFrom != null && _dateTo != null;
    return GestureDetector(
      onTap: _pickDateRange,
      onLongPress: active
          ? () => setState(() {
                _dateFrom = null;
                _dateTo = null;
              })
          : null,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primaryBlue : AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: active ? AppColors.primaryBlue : AppColors.greyText),
            const SizedBox(width: 6),
            Text(
              'Date Range',
              style: TextStyle(
                color: active ? AppColors.primaryBlue : AppColors.greyText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status pill for an event; deleted events get their own "Deleted" pill.
  Widget _buildBadge(ActivityEvent e) {
    if (e.type == ActivityType.deleted || e.status == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.statRedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.statRed, size: 13),
            SizedBox(width: 4),
            Text(
              'Deleted',
              style: TextStyle(
                color: AppColors.statRed,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return StatusBadge(status: e.status!, showIcon: true);
  }

  Widget _buildEventCard(ActivityEvent e) {
    final device = e.deviceDetail;
    return GestureDetector(
      onTap: () => _openEvent(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
            Icon(iconForDeviceType(e.deviceName), color: AppColors.greyText, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.ticketNumber,
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (e.deviceName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      device.isEmpty ? e.deviceName : '${e.deviceName} • $device',
                      style: TextStyle(color: AppColors.greyText, fontSize: 12),
                    ),
                  ],
                  if (e.customerName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 13, color: AppColors.greyText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.customerName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.darkText, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (e.contactNumber != null && e.contactNumber!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.call_outlined, size: 13, color: AppColors.greyText),
                        const SizedBox(width: 4),
                        Text(
                          e.contactNumber!,
                          style: TextStyle(color: AppColors.darkText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBadge(e),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.greyText),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(e.createdAt),
                      style: TextStyle(color: AppColors.greyText, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  e.message,
                  style: TextStyle(color: AppColors.greyText, fontSize: 11),
                ),
                if (e.actorName != null && e.actorName!.isNotEmpty)
                  Text(
                    'by ${e.actorName}',
                    style: TextStyle(color: AppColors.greyText, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }
}
