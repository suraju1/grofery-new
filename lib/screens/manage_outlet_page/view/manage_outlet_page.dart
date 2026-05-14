import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:grofery_user/config/global.dart';
import 'package:grofery_user/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';

class ManageOutletPage extends StatelessWidget {
  const ManageOutletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F9), // Light greyish background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
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
      body: BlocBuilder<UserProfileBloc, UserProfileState>(
        builder: (context, state) {
          // Default to Global.userData
          var userData = Global.userData;

          // If the profile API returned data, use it for freshness
          if (state is UserProfileLoaded && state.userData.data != null) {
            final apiData = state.userData.data!;
            userData = userData?.copyWith(
              name: apiData.name,
              shopName: apiData.shopName,
              email: apiData.email,
              mobile: apiData.mobile,
            );
          }

          if (userData == null) {
            return const Center(child: Text("No data found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Add New Outlet Button
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: Colors.grey.shade200),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text(
                //         'Add a new outlet',
                //         style: TextStyle(
                //           color: Colors.red.shade400,
                //           fontSize: 16,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //       Icon(Icons.add, color: Colors.red.shade400, size: 20),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 16),

                // Outlet Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
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
                                Text(
                                  userData.shopName.isNotEmpty
                                      ? userData.shopName
                                      : 'My Outlet',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  userData.name.isNotEmpty
                                      ? userData.name
                                      : 'No Name Available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Row(
                          //   children: [
                          //     Icon(TablerIcons.edit,
                          //         color: Colors.red.shade400, size: 18),
                          //     const SizedBox(width: 4),
                          //     Text(
                          //       'edit',
                          //       style: TextStyle(
                          //         color: Colors.red.shade400,
                          //         fontWeight: FontWeight.w600,
                          //         fontSize: 14,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(TablerIcons.phone,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            userData.mobile.isNotEmpty
                                ? userData.mobile
                                : 'N/A',
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
                          Icon(TablerIcons.mail,
                              color: Colors.grey.shade600, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            userData.email.isNotEmpty ? userData.email : 'N/A',
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
