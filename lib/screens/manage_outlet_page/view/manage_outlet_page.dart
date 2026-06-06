import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/utils/widgets/custom_circular_progress_indicator.dart';
import '../bloc/manage_outlets_bloc.dart';
import '../bloc/manage_outlets_event.dart';
import '../bloc/manage_outlets_state.dart';
import '../model/outlet_model.dart';

class ManageOutletPage extends StatelessWidget {
  const ManageOutletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ManageOutletsBloc()..add(FetchOutlets()),
      child: const ManageOutletView(),
    );
  }
}

class ManageOutletView extends StatelessWidget {
  const ManageOutletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9), // Light greyish background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: const Text(
          'Manage Outlets',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocBuilder<ManageOutletsBloc, ManageOutletsState>(
        builder: (context, state) {
          if (state is OutletsLoading) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          if (state is OutletsError) {
            return Center(child: Text("Error: ${state.message}"));
          }

          List<OutletModel> outlets = [];
          if (state is OutletsLoaded) {
            outlets = state.outlets;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add New Outlet Button
                GestureDetector(
                  onTap: () {
                    GoRouter.of(context).push(AppRoutes.addOutlet).then((_) {
                      // Refresh the list when returning
                      context.read<ManageOutletsBloc>().add(FetchOutlets());
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add a new outlet',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.add, color: Colors.red.shade400, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Outlets List
                Expanded(
                  child: outlets.isEmpty
                      ? const Center(child: Text("No outlets found."))
                      : ListView.builder(
                          itemCount: outlets.length,
                          itemBuilder: (context, index) {
                            final outlet = outlets[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: outlet.isDefault == true ? Colors.green.shade300 : Colors.grey.shade200,
                                  width: outlet.isDefault == true ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  outlet.shopName ?? 'My Outlet',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (outlet.isDefault == true) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.green.shade200),
                                                    ),
                                                    child: const Text(
                                                      "Default",
                                                      style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                                    ),
                                                  )
                                                ]
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              [outlet.addressLine1, outlet.city, outlet.state].where((e) => e != null && e.isNotEmpty).join(', '),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          context.read<ManageOutletsBloc>().add(DeleteOutlet(id: outlet.id!));
                                        },
                                        child: Row(
                                          children: [
                                            Icon(TablerIcons.trash, color: Colors.red.shade400, size: 18),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Divider(color: Colors.grey.shade200, height: 1),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(TablerIcons.phone, color: Colors.grey.shade600, size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        (outlet.mobile != null && outlet.mobile!.isNotEmpty) ? outlet.mobile! : 'N/A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(TablerIcons.mail, color: Colors.grey.shade600, size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        (outlet.email != null && outlet.email!.isNotEmpty) ? outlet.email! : 'N/A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
