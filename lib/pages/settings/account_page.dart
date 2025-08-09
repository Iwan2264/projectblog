import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';
import 'package:projectblog/widgets/cached_network_image.dart';
import 'package:projectblog/utils/navigation_helper.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with AutomaticKeepAliveClientMixin {
  final SettingsController controller = Get.find<SettingsController>();
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        // This ensures proper state refresh when navigating back
        NavigationHelper.back(result: {'pagePopped': true});
        return false;
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    controller.getProfileImageSource() != null
                        ? (controller.isNetworkImage() 
                            ? CachedAvatar(
                                imageUrl: controller.getProfileImageSource(),
                                radius: 40,
                                backgroundColor: theme.colorScheme.surface,
                                fallback: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.surface,
                                  child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                                ),
                              )
                            : CircleAvatar(
                                radius: 40,
                                backgroundColor: theme.colorScheme.surface,
                                backgroundImage: FileImage(controller.getProfileImageSource()),
                              ))
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.colorScheme.surface,
                            child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: Obx(() => InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: controller.isUploading.value ? null : controller.pickImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: controller.isUploading.value
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                  helperText: 'Your display name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.length > 50) {
                    return 'Name cannot exceed 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  helperText: 'Optional contact number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic phone validation
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description_outlined),
                  helperText: 'Tell others about yourself (max 160 chars)',
                  counterText: '${controller.bioController.text.length}/160',
                ),
                maxLines: 3,
                maxLength: 160,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                validator: (value) {
                  if (value != null && value.length > 160) {
                    return 'Bio cannot exceed 160 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Interests', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 6),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: controller.allInterests.map((interest) {
                  final selected = controller.selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (val) {
                      if (val) {
                        controller.selectedInterests.add(interest);
                      } else {
                        controller.selectedInterests.remove(interest);
                      }
                    },
                  );
                }).toList(),
              )),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                onPressed: controller.isSaving.value 
                  ? null 
                  : () {
                      if (controller.formKey.currentState!.validate()) {
                        controller.saveProfile();
                      }
                    },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: controller.isSaving.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Saving...'),
                      ],
                    )
                  : const Text('Save Changes'),
              )),
            ],
          ),
        ),
      ),
    ),
    );
  }
}