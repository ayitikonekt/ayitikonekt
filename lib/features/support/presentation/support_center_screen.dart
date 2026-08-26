import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_locale_provider.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/xfile_image.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';

class SupportCenterScreen extends StatefulWidget {
  final String userId;
  final String initialContact;

  const SupportCenterScreen({
    super.key,
    required this.userId,
    this.initialContact = '',
  });

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _faqs = <({String question, String answer, String category})>[
    (
      question: 'faqPublishQuestion',
      answer: 'faqPublishAnswer',
      category: 'supportListings',
    ),
    (
      question: 'faqEditQuestion',
      answer: 'faqEditAnswer',
      category: 'supportListings',
    ),
    (
      question: 'faqPasswordQuestion',
      answer: 'faqPasswordAnswer',
      category: 'supportAccount',
    ),
    (
      question: 'faqReviewQuestion',
      answer: 'faqReviewAnswer',
      category: 'supportReviews',
    ),
    (
      question: 'faqSafetyQuestion',
      answer: 'faqSafetyAnswer',
      category: 'supportSafety',
    ),
    (
      question: 'faqLanguageQuestion',
      answer: 'faqLanguageAnswer',
      category: 'supportAccount',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTicketForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketForm(
        userId: widget.userId,
        initialContact: widget.initialContact,
      ),
    );
    if (!mounted || created != true) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('ticketCreated'))));
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleFaqs = _faqs.where((faq) {
      if (normalizedQuery.isEmpty) return true;
      return '${context.tr(faq.question)} ${context.tr(faq.answer)} ${context.tr(faq.category)}'
          .toLowerCase()
          .contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leadingWidth: 112,
        leading: const AppBackButton(
          showWhenCannotPop: false,
          foregroundColor: Colors.white,
        ),
        title: Text(context.tr('helpCenter')),
        centerTitle: true,
        backgroundColor: const Color(0xFF0646D8),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 600 ? 14 : 24,
                  20,
                  constraints.maxWidth < 600 ? 14 : 24,
                  36,
                ),
                children: [
                  Text(
                    context.tr('howCanWeHelp'),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: context.tr('searchHelp'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.tr('clear'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _QuickActions(onCreateTicket: _openTicketForm),
                  const SizedBox(height: 26),
                  Text(
                    context.tr('frequentQuestions'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (visibleFaqs.isEmpty)
                    _EmptyResult(message: context.tr('noHelpResults'))
                  else
                    ...visibleFaqs.map(
                      (faq) => Card(
                        margin: const EdgeInsets.only(bottom: 9),
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.help_outline_rounded,
                            color: Color(0xFF0646D8),
                          ),
                          title: Text(
                            context.tr(faq.question),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(context.tr(faq.category)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(context.tr(faq.answer)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  Text(
                    context.tr('myRequests'),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TicketList(userId: widget.userId),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _openTicketForm,
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(context.tr('contactSupport')),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('supportNotEmergency'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onCreateTicket;

  const _QuickActions({required this.onCreateTicket});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 600
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ActionCard(
            width: width,
            icon: Icons.menu_book_outlined,
            title: context.tr('quickGuides'),
            subtitle: context.tr('quickGuidesHelp'),
          ),
          _ActionCard(
            width: width,
            icon: Icons.support_agent_rounded,
            title: context.tr('contactSupport'),
            subtitle: context.tr('contactSupportHelp'),
            onTap: onCreateTicket,
          ),
        ],
      );
    },
  );
}

class _ActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF1FF),
                child: Icon(icon, color: const Color(0xFF0646D8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TicketList extends StatelessWidget {
  final String userId;

  const _TicketList({required this.userId});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SupportTicket>>(
    stream: SupportService().ticketsFor(userId),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text(context.tr('ticketsLoadError'));
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final tickets = snapshot.data!;
      if (tickets.isEmpty) {
        return _EmptyResult(message: context.tr('noRequests'));
      }
      return Column(
        children: tickets
            .map(
              (ticket) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF1FF),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      color: Color(0xFF0646D8),
                    ),
                  ),
                  title: Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '#${ticket.id.substring(0, ticket.id.length > 8 ? 8 : ticket.id.length)} · ${context.tr('ticketStatus_${ticket.status}')}',
                  ),
                  trailing: _StatusBadge(status: ticket.status),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF1FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      context.tr('ticketStatus_$status'),
      style: const TextStyle(
        color: Color(0xFF0646D8),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _EmptyResult extends StatelessWidget {
  final String message;
  const _EmptyResult({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF667085)),
    ),
  );
}

class _TicketForm extends StatefulWidget {
  final String userId;
  final String initialContact;
  const _TicketForm({required this.userId, required this.initialContact});

  @override
  State<_TicketForm> createState() => _TicketFormState();
}

class _TicketFormState extends State<_TicketForm> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  late final TextEditingController _contact;
  final _images = <XFile>[];
  String _category = 'supportTechnical';
  bool _saving = false;

  static const _categories = [
    'supportAccount',
    'supportListings',
    'supportSafety',
    'supportReviews',
    'supportTechnical',
    'supportOther',
  ];

  @override
  void initState() {
    super.initState();
    _contact = TextEditingController(text: widget.initialContact);
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final selected = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (!mounted) return;
    setState(() {
      for (final image in selected) {
        if (_images.length == 3) break;
        _images.add(image);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await SupportService().createTicket(
        userId: widget.userId,
        category: _category,
        subject: _subject.text,
        description: _description.text,
        contact: _contact.text,
        attachments: _images,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('ticketSaveError'))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(24),
              bottom: Radius.circular(screenWidth >= 700 ? 24 : 0),
            ),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.tr('newSupportRequest'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: context.tr('category'),
                    ),
                    items: _categories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(context.tr(item)),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _subject,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: context.tr('subject'),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 4
                        ? context.tr('requiredField')
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 1200,
                    decoration: InputDecoration(
                      labelText: context.tr('describeProblem'),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                        ? context.tr('descriptionTooShort')
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _contact,
                    decoration: InputDecoration(
                      labelText: context.tr('contactEmailPhone'),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? context.tr('requiredField')
                        : null,
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: _images.length >= 3 || _saving
                        ? null
                        : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      '${context.tr('addScreenshots')} (${_images.length}/3)',
                    ),
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 9),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 82,
                                height: 82,
                                child: XFileImage(file: _images[index]),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _images.removeAt(index)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      context.tr(_saving ? 'sending' : 'sendRequest'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
