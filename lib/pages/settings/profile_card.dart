import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';

class ProfileInfoWidget extends StatelessWidget {
  final SettingsController controller;

  const ProfileInfoWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Card(
        elevation: 3,
        color: theme.colorScheme.surface.withAlpha(225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.isEditing.value ? controller.pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.surface,
                          backgroundImage: controller.profileImage.value != null
                              ? FileImage(controller.profileImage.value!)
                              : null,
                          child: controller.profileImage.value == null
                              ? Icon(
                                  Icons.person,
                                  size: 32,
                                    color: theme.colorScheme.primary.withAlpha(100),
                                )
                              : null,
                        ),
                        if (controller.isEditing.value)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.isEditing.value
                            ? TextFormField(
                                controller: controller.nameController,
                                style: theme.textTheme.bodyLarge,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: InputBorder.none,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Enter name' : null,
                              )
                            : Text(
                                controller.name.value,
                                style: theme.textTheme.titleMedium,
                              ),
                        controller.isEditing.value
                            ? TextFormField(
                                controller: controller.usernameController,
                                style: theme.textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: InputBorder.none,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Enter username' : null,
                              )
                            : Text(
                                controller.username.value,
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                              ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: controller.toggleEdit,
                    child: Text(controller.isEditing.value ? 'Save' : 'Edit'),
                  ),
                ],
              ),
              const Divider(height: 24),
              controller.isEditing.value
                  ? Column(
                      children: [
                        TextFormField(
                          controller: controller.emailController,
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: controller.phoneController,
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter phone' : null,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Email:'),
                            Text(
                              controller.email.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Phone:'),
                            Text(
                              controller.phone.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    ));
  }
}