import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MessagesPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const MessagesPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;

  final _conversations = [
    _Convo('Jessica Manager', 'Please make the logo bigger 😊', '3:30 PM', 2, false),
    _Convo('Sarah Designer', 'Here is the updated design!', '2:15 PM', 0, true),
    _Convo('Mike Developer', 'Alright, sure I will update it', '1:45 PM', 1, false),
    _Convo('Support Team', 'Your ticket has been resolved', 'Yesterday', 0, true),
    _Convo('Team Group', 'New project assets uploaded', 'Yesterday', 5, false),
    _Convo('Alex Client', 'Looks great! Approved ✅', 'Mon', 0, true),
    _Convo('Fashion Brand', 'Can we change the color scheme?', 'Mon', 0, false),
    _Convo('Tech Company', 'When will the posts go live?', 'Sun', 0, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
        ),

        // Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: ['All', 'Manager', 'Designer', 'Team'].asMap().entries.map((e) {
              final isSelected = e.key == _selectedTab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: isSelected ? widget.gradient : null,
                      color: isSelected ? null : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ).animate(delay: 100.ms).fadeIn(),
        ),

        const SizedBox(height: 12),

        // Conversations List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _conversations.length,
            itemBuilder: (context, i) {
              final c = _conversations[i];
              return _ConvoTile(
                convo: c,
                accentColor: widget.accentColor,
                gradient: widget.gradient,
                index: i,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConvoTile extends StatelessWidget {
  final _Convo convo;
  final Color accentColor;
  final LinearGradient gradient;
  final int index;

  const _ConvoTile({
    required this.convo,
    required this.accentColor,
    required this.gradient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openChat(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      convo.name[0],
                      style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                if (convo.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(convo.name,
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: convo.unread > 0 ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(convo.time,
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              color: convo.unread > 0 ? accentColor : AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: convo.unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: convo.unread > 0 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (convo.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${convo.unread}',
                                style: GoogleFonts.sora(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn().slideX(begin: 0.1, end: 0),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChatScreen(name: convo.name, accentColor: accentColor, gradient: gradient),
      ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final String name;
  final Color accentColor;
  final LinearGradient gradient;
  const _ChatScreen({required this.name, required this.accentColor, required this.gradient});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _msgController = TextEditingController();
  final _scroll = ScrollController();

  final _messages = [
    _Message('Please make the logo bigger 😊', false, '3:28 PM'),
    _Message('Sure, I will update it right away!', true, '3:29 PM'),
    _Message('Also change the background color to dark navy', false, '3:30 PM'),
    _Message('Got it! Updating now...', true, '3:31 PM'),
    _Message('Here is the updated version, let me know!', true, '3:45 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: AppColors.textPrimary),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(gradient: widget.gradient, shape: BoxShape.circle),
              child: Center(
                child: Text(widget.name[0],
                    style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: GoogleFonts.sora(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('Online',
                    style: GoogleFonts.sora(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return _ChatBubble(msg: m, accentColor: widget.accentColor, gradient: widget.gradient);
              },
            ),
          ),
          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_msgController.text.trim().isNotEmpty) {
                      setState(() {
                        _messages.add(_Message(_msgController.text.trim(), true, 'Now'));
                        _msgController.clear();
                      });
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: widget.accentColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _Message msg;
  final Color accentColor;
  final LinearGradient gradient;
  const _ChatBubble({required this.msg, required this.accentColor, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: msg.isMine ? gradient : null,
                color: msg.isMine ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isMine ? 16 : 4),
                  bottomRight: Radius.circular(msg.isMine ? 4 : 16),
                ),
                border: msg.isMine ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: msg.isMine ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Convo {
  final String name, lastMessage, time;
  final int unread;
  final bool isOnline;
  const _Convo(this.name, this.lastMessage, this.time, this.unread, this.isOnline);
}

class _Message {
  final String text, time;
  final bool isMine;
  const _Message(this.text, this.isMine, this.time);
}
