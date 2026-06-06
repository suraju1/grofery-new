import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grofery_user/router/app_routes.dart';
import 'package:grofery_user/utils/widgets/custom_button.dart';
import 'package:grofery_user/utils/widgets/custom_textfield.dart';

import '../bloc/manage_outlets_bloc.dart';
import '../bloc/manage_outlets_event.dart';
import '../bloc/manage_outlets_state.dart';

class AddOutletPage extends StatelessWidget {
  const AddOutletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ManageOutletsBloc(),
      child: const AddOutletView(),
    );
  }
}

class AddOutletView extends StatefulWidget {
  const AddOutletView({super.key});

  @override
  State<AddOutletView> createState() => _AddOutletViewState();
}

class _AddOutletViewState extends State<AddOutletView> {
  final _formKey = GlobalKey<FormState>();
  
  final _shopNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  // Location Fields
  String? _addressLine1;
  String? _city;
  String? _state;
  String? _zipcode;
  String? _country;
  String? _latitude;
  String? _longitude;
  
  bool _isSaving = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  void _pickLocation() async {
    final result = await GoRouter.of(context).push(
      AppRoutes.locationPicker,
      extra: {
        'isFromAddressPage': false,
        'isEdit': false,
      },
    );

    if (result != null && result is Map) {
      final LatLng? location = result['location'];
      final String? address = result['address'];

      if (location != null) {
        setState(() {
          _latitude = location.latitude.toString();
          _longitude = location.longitude.toString();
          _addressLine1 = address ?? '';
          // We can parse full address if needed, for now just use line1 or assume map returned it
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an outlet location on the map')),
        );
        return;
      }

      final Map<String, dynamic> data = {
        'shop_name': _shopNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'address_line1': _addressLine1,
        'city': _city ?? '',
        'state': _state ?? '',
        'zipcode': _zipcode ?? '',
        'country': _country ?? 'India',
        'latitude': _latitude,
        'longitude': _longitude,
        'is_default': false,
      };

      setState(() {
        _isSaving = true;
      });
      context.read<ManageOutletsBloc>().add(AddOutlet(outletData: data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageOutletsBloc, ManageOutletsState>(
      listener: (context, state) {
        if (state is AddOutletSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outlet added successfully!')),
          );
          GoRouter.of(context).pop();
        } else if (state is AddOutletError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Add New Outlet',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => GoRouter.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Outlet Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _shopNameController,
                  labelText: "Shop / Outlet Name",
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _mobileController,
                  labelText: "Mobile Number",
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _emailController,
                  labelText: "Email (Optional)",
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _gstController,
                  labelText: "GST Number (Optional)",
                ),
                
                const SizedBox(height: 24),
                const Text("Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _latitude != null 
                              ? "Location Selected\n${_addressLine1 ?? ''}"
                              : "No location selected",
                          style: TextStyle(color: _latitude != null ? Colors.black87 : Colors.grey.shade600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.map),
                        label: const Text("Pick on Map"),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: _isSaving ? null : _submit,
                    text: _isSaving ? "Saving..." : "Save Outlet",
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
