import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';

/// The filter selections the user has made, handed back to the caller
/// when they tap Apply.
class RepairFilters {
  final Set<RepairStatus> statuses;
  final String deviceType;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const RepairFilters({
    required this.statuses,
    this.deviceType = 'All Devices',
    this.dateFrom,
    this.dateTo,
  });

  RepairFilters copyWith({
    Set<RepairStatus>? statuses,
    String? deviceType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return RepairFilters(
      statuses: statuses ?? this.statuses,
      deviceType: deviceType ?? this.deviceType,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

/// Shows the filter sheet as a rounded modal bottom sheet.
/// Returns the applied [RepairFilters], or null if the user dismissed it
/// without applying.
Future<RepairFilters?> showRepairFilterSheet(
  BuildContext context, {
  required RepairFilters initialFilters,
}) {
  return showModalBottomSheet<RepairFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RepairFilterSheet(initialFilters: initialFilters),
  );
}

class _RepairFilterSheet extends StatefulWidget {
  final RepairFilters initialFilters;

  const _RepairFilterSheet({required this.initialFilters});

  @override
  State<_RepairFilterSheet> createState() => _RepairFilterSheetState();
}

class _RepairFilterSheetState extends State<_RepairFilterSheet> {
  late Set<RepairStatus> _selectedStatuses;
  late String _deviceType;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  final List<String> _deviceTypes = const [
    'All Devices',
    'Laptop',
    'Phone',
    'Desktop',
    'Tablet',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatuses = {...widget.initialFilters.statuses};
    _deviceType = widget.initialFilters.deviceType;
    _dateFrom = widget.initialFilters.dateFrom;
    _dateTo = widget.initialFilters.dateTo;
  }

  bool get _allSelected => _selectedStatuses.length == RepairStatus.values.length;

  void _toggleAll(bool? value) {
    setState(() {
      _selectedStatuses = (value ?? false) ? {...RepairStatus.values} : {};
    });
  }

  void _toggleStatus(RepairStatus status, bool? value) {
    setState(() {
      if (value ?? false) {
        _selectedStatuses.add(status);
      } else {
        _selectedStatuses.remove(status);
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _reset() {
    setState(() {
      _selectedStatuses = {};
      _deviceType = 'All Devices';
      _dateFrom = null;
      _dateTo = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      RepairFilters(
        statuses: _selectedStatuses,
        deviceType: _deviceType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: [
                    Text(
                      'Filter by Status',
                      style: TextStyle(
                          color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    _buildCheckRow(
                      label: 'All',
                      value: _allSelected,
                      color: AppColors.primaryBlue,
                      onChanged: _toggleAll,
                    ),
                    for (final status in RepairStatus.values)
                      _buildCheckRow(
                        label: status.label,
                        value: _selectedStatuses.contains(status),
                        color: status.color,
                        onChanged: (v) => _toggleStatus(status, v),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Filter by Device Type',
                      style: TextStyle(
                          color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _buildDeviceDropdown(),
                    const SizedBox(height: 20),
                    Text(
                      'Date Range',
                      style: TextStyle(
                          color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildDateField('From', _dateFrom, isFrom: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildDateField('To', _dateTo, isFrom: false)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Reset',
                              style: TextStyle(
                                  color: AppColors.primaryBlue, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Apply',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckRow({
    required String label,
    required bool value,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
            Text(label, style: TextStyle(color: AppColors.darkText, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: _deviceType,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: _deviceTypes
            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _deviceType = v);
        },
      ),
    );
  }

  Widget _buildDateField(String hint, DateTime? value, {required bool isFrom}) {
    return GestureDetector(
      onTap: () => _pickDate(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value != null ? _formatDate(value) : hint,
              style: TextStyle(
                color: value != null ? AppColors.darkText : AppColors.greyText,
                fontSize: 13,
              ),
            ),
            Icon(Icons.calendar_today_outlined, color: AppColors.greyText, size: 16),
          ],
        ),
      ),
    );
  }
}
