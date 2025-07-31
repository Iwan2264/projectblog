import 'package:flutter/material.dart';
enum BlogStatus { published, scheduled, draft }

class BlogSection extends StatefulWidget {
  const BlogSection({super.key});
  @override
  State<BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<BlogSection> {
  BlogStatus _selectedStatus = BlogStatus.published;

  // Example dummy data, replace with your actual controller logic
  // final List<BlogModel> _allBlogs = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                TabButton(
                  label: "Published",
                  isSelected: _selectedStatus == BlogStatus.published,
                  onTap: () => setState(() => _selectedStatus = BlogStatus.published),
                ),
                TabButton(
                  label: "Scheduled",
                  isSelected: _selectedStatus == BlogStatus.scheduled,
                  onTap: () => setState(() => _selectedStatus = BlogStatus.scheduled),
                ),
                TabButton(
                  label: "Draft",
                  isSelected: _selectedStatus == BlogStatus.draft,
                  onTap: () => setState(() => _selectedStatus = BlogStatus.draft),
                ),
              ],
            ),
            InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  Text("Create New", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  Icon(Icons.edit, color: Colors.deepPurple, size: 18),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: IndexedStack(
            index: _selectedStatus.index,
            children: [
              _buildBlogGrid("Published Blog"),
              _buildBlogGrid("Scheduled Blog"),
              _buildBlogGrid("Draft Blog"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlogGrid(String type) {
    return GridView.builder(
      itemCount: 4, // Replace with your list's length
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return Card(
          child: Center(child: Text("$type ${index + 1}")),
        );
      },
    );
  }
}

class TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.deepPurple : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}