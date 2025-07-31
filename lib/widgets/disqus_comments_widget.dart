import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui_web' as ui;

import '../models/blog_model.dart';

class DisqusCommentsWidget extends StatefulWidget {
  final BlogModel blog;
  final String disqusShortname;

  const DisqusCommentsWidget({
    Key? key,
    required this.blog,
    required this.disqusShortname,
  }) : super(key: key);

  @override
  State<DisqusCommentsWidget> createState() => _DisqusCommentsWidgetState();
}

class _DisqusCommentsWidgetState extends State<DisqusCommentsWidget> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _setupDisqusContainer();
      _loadDisqus();
    }
  }

  void _setupDisqusContainer() {
    // Register the HTML element
    ui.platformViewRegistry.registerViewFactory(
      'disqus-${widget.blog.id}',
      (int viewId) {
        final html.DivElement element = html.DivElement()
          ..id = 'disqus_thread'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      },
    );
  }

  void _loadDisqus() {
    // Create Disqus configuration
    final disqusConfig = '''
      var disqus_config = function () {
        this.page.url = '${_getPageUrl()}';
        this.page.identifier = '${widget.blog.id}';
        this.page.title = '${widget.blog.title.replaceAll("'", "\\'")}';
      };
      
      (function() {
        var d = document, s = d.createElement('script');
        s.src = 'https://${widget.disqusShortname}.disqus.com/embed.js';
        s.setAttribute('data-timestamp', +new Date());
        (d.head || d.body).appendChild(s);
      })();
    ''';

    // Inject script into page
    html.ScriptElement script = html.ScriptElement()
      ..type = 'text/javascript'
      ..innerHtml = disqusConfig;
    
    html.document.head?.append(script);
  }

  String _getPageUrl() {
    if (kIsWeb) {
      return html.window.location.href;
    }
    // For mobile apps, you might want to use a deep link or web URL
    return 'https://yourblog.com/blog/${widget.blog.id}';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // For mobile apps, show a message or redirect to web
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.comment, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'View and add comments by opening this post in your web browser.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInBrowser(),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Disqus comments will be loaded here
          Container(
            height: 400, // Adjust height as needed
            child: kIsWeb
                ? HtmlElementView(viewType: 'disqus-${widget.blog.id}')
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _openInBrowser() async {
    final url = _getPageUrl();
    try {
      // Copy URL to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: url));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied to clipboard! Open in your browser to view comments.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL: $url'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

// Configuration class for Disqus
class DisqusConfig {
  static const String shortname = 'your-disqus-shortname'; // Replace with your Disqus shortname
  
  // Optional: Additional configuration
  static const Map<String, dynamic> config = {
    'language': 'en',
    'colorScheme': 'light', // or 'dark'
  };
}

// Helper widget to show comment count
class DisqusCommentCount extends StatelessWidget {
  final BlogModel blog;
  final String disqusShortname;

  const DisqusCommentCount({
    Key? key,
    required this.blog,
    required this.disqusShortname,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // For mobile, show placeholder
      return const Text(
        'Comments',
        style: TextStyle(color: Colors.grey),
      );
    }

    return InkWell(
      onTap: () {
        // Scroll to comments section
        html.document.getElementById('disqus_thread')?.scrollIntoView();
      },
      child: const Text(
        'View Comments',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
