import 'package:flutter/material.dart';
import '../widgets/category_widget.dart';

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
    // Use the same categories as in category_widget.dart for consistency
    final categories = [
      'Technology', 'Health & Wellness', 'Finance & Investing', 'Travel',
      'Food & Recipes', 'Lifestyle & Fashion', 'Business & Marketing',
      'Education', 'Arts & Culture', 'Science', 'Personal Growth', 'Sports & Gaming'
    ];
    final categoryImageGetter = CategoriesSection().getCategoryImage;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        hintText: 'Select a category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      value: categories.contains(selectedCategory) ? selectedCategory : null,
      onChanged: (value) {
        if (value != null) {
          onCategoryChanged(value);
        }
      },
      items: categories.map((category) {
        final imagePath = categoryImageGetter(category)['image'];
        return DropdownMenuItem<String>(
          value: category,
          child: Row(
            children: [
              Image.asset(
                imagePath!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 20),
              ),
              const SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
    );
  }
}
