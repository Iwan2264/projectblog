import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectblog/controllers/settings_controller.dart';

class ProfileInfoWidget extends StatelessWidget {
  final SettingsController controller;

  const ProfileInfoWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          backgroundImage: controller.profileImage.value != null
                              ? FileImage(controller.profileImage.value!)
                              : null,
                          child: controller.profileImage.value == null
                              ? Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
                                color: Theme.of(context).colorScheme.primary,
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
                                style: Theme.of(context).textTheme.bodyLarge,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: InputBorder.none,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Enter name' : null,
                              )
                            : Text(
                                controller.name.value,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                        controller.isEditing.value
                            ? TextFormField(
                                controller: controller.usernameController,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: InputBorder.none,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty ? 'Enter username' : null,
                              )
                            : Text(
                                controller.username.value,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey),
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
                              style: Theme.of(context).textTheme.bodyMedium,
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
                              style: Theme.of(context).textTheme.bodyMedium,
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