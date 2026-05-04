import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grofery_user/config/theme.dart';
import 'package:grofery_user/screens/cart_page/model/get_cart_model.dart';
import '../../../config/constant.dart';

class DeliveryTimeSlotWidget extends StatefulWidget {
  final List<TimeSlot>? timeSlots;
  final Function(TimeSlot?)? onSlotSelected;
  final TimeSlot? initialSelectedSlot;

  const DeliveryTimeSlotWidget({
    super.key, 
    this.timeSlots, 
    this.onSlotSelected,
    this.initialSelectedSlot,
  });

  @override
  State<DeliveryTimeSlotWidget> createState() => _DeliveryTimeSlotWidgetState();
}

class _DeliveryTimeSlotWidgetState extends State<DeliveryTimeSlotWidget> {
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.initialSelectedSlot;
    
    // Auto-select first slot if none selected and slots are available
    if (_selectedSlot == null && widget.timeSlots != null && widget.timeSlots!.isNotEmpty) {
      _selectedSlot = widget.timeSlots!.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onSlotSelected != null) {
          widget.onSlotSelected!(_selectedSlot);
        }
      });
    }
  }

  @override
  void didUpdateWidget(DeliveryTimeSlotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeSlots != oldWidget.timeSlots) {
       if (_selectedSlot == null && widget.timeSlots != null && widget.timeSlots!.isNotEmpty) {
        _selectedSlot = widget.timeSlots!.first;
        if (widget.onSlotSelected != null) {
          widget.onSlotSelected!(_selectedSlot);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.timeSlots ?? [];
    
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Time Slot',
            style: TextStyle(
              fontSize: isTablet(context) ? 24 : 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Choose your preferred delivery time',
            style: TextStyle(
              fontSize: isTablet(context) ? 14 : 10.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slots.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final slot = slots[index];
              final isSelected = _selectedSlot?.id == slot.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                  if (widget.onSlotSelected != null) {
                    widget.onSlotSelected!(slot);
                  }
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      width: isSelected ? 1.5 : 1,
                    ),
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.05)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (slot.name != null && slot.name!.isNotEmpty)
                              Text(
                                slot.name!,
                                style: TextStyle(
                                  fontSize: isTablet(context) ? 16 : 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                ),
                              ),
                            Text(
                              "${slot.from} - ${slot.to}",
                              style: TextStyle(
                                fontSize: isTablet(context) ? 14 : 12.sp,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.8) : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
