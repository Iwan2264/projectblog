import 'package:flutter/material.dart';
import 'package:projectblog/pages/home/widgets/published_card.dart';
import 'package:projectblog/pages/home/widgets/scheduled_card.dart';
import 'package:projectblog/pages/home/widgets/draft_card.dart';
import 'package:projectblog/pages/blog/create_post_page.dart';
class BlogSection extends StatefulWidget {
  const BlogSection({super.key});
  @override
  State<BlogSection> createState() => _BlogSectionState();
}

class _BlogSectionState extends State<BlogSection> {
  BlogStatus _selectedStatus = BlogStatus.published;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreatePostPage()),
              );
              },
              child: Row(
              children: [
                Text(
                "Create New",
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, color: theme.colorScheme.primary, size: 18),
              ],
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        IndexedStack(
            index: _selectedStatus.index,
            children: const [
              PublishedBlogsGrid(),
              ScheduledBlogsGrid(),
              DraftsGrid(),
            ],
          ),
      ],
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha(150),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

enum BlogStatus { published, scheduled, draft }