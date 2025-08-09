import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  
  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final categories = [
      'Tech', 'Business', 'Health', 'Sports', 'Travel', 
      'Food', 'Fashion', 'Science', 'Education', 'Art',
      'Finance', 'Growth'
    ];
    
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        hintText: 'Select a category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      value: selectedCategory.isNotEmpty ? selectedCategory : null,
      onChanged: (value) {
        if (value != null) {
          onCategoryChanged(value);
        }
      },
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _getCategoryIcon(String category) {
    IconData iconData;
    
    switch (category.toLowerCase()) {
      case 'tech':
        iconData = Icons.computer;
        break;
      case 'business':
        iconData = Icons.business;
        break;
      case 'health':
        iconData = Icons.health_and_safety;
        break;
      case 'sports':
        iconData = Icons.sports;
        break;
      case 'travel':
        iconData = Icons.travel_explore;
        break;
      case 'food':
        iconData = Icons.restaurant;
        break;
      case 'fashion':
        iconData = Icons.shopping_bag;
        break;
      case 'science':
        iconData = Icons.science;
        break;
      case 'education':
        iconData = Icons.school;
        break;
      case 'art':
        iconData = Icons.palette;
        break;
      case 'finance':
        iconData = Icons.attach_money;
        break;
      case 'growth':
        iconData = Icons.trending_up;
        break;
      default:
        iconData = Icons.category;
    }
    
    return Icon(iconData, size: 20);
  }
}
