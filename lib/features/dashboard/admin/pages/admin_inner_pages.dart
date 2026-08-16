import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, FilteringTextInputFormatter, TextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../model/admin_user_model.dart';
import '../../../../shared/widgets/common_widgets.dart';

// ─────────────────────────────────────────
// CLIENTS PAGE  — real API
// ─────────────────────────────────────────
class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});
  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
  final _apiService = ApiService();
  final _searchCtrl = TextEditingController();

  List<AdminUserModel> _all = [];
  List<AdminUserModel> _filtered = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applySearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchClients({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      if (refresh) _errorMsg = null;
    });

    try {
      final response = await _apiService.get(
        AppConstants.adminClients,
        queryParams: {
          'page': '1',
          'limit': '50',
          if (_searchCtrl.text.trim().isNotEmpty)
            'search': _searchCtrl.text.trim(),
        },
      );

      final raw = response['data']?['clients'] ?? [];

      final list = (raw as List)
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList();

      setState(() {
        _all = list;
        _filtered = list;
        _isLoading = false;
      });

      print("Loaded clients: ${list.length}");
    } catch (e) {
      setState(() {
        _errorMsg = _cleanErr(e.toString());
        _isLoading = false;
      });

      print(e);
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((u) =>
      u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phone ?? '').contains(q) ||
          (u.companyName ?? '').toLowerCase().contains(q) ||
          (u.industry ?? '').toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _deleteClient(AdminUserModel user) async {
    final ok = await _showDeleteDialog(context, user.name, user.email);
    if (!ok || !mounted) return;
    try {
      final res = await _apiService.delete('${AppConstants.adminDeleteUser}/${user.id}');
      final msg = (res['msg'] ?? res['message'] ?? 'Client deleted successfully').toString();
      setState(() { _all.removeWhere((u) => u.id == user.id); _filtered.removeWhere((u) => u.id == user.id); });
      if (mounted) _snack(msg, false);
    } catch (e) {
      if (mounted) _snack(_cleanErr(e.toString()), true);
    }
  }

  void _snack(String msg, bool isError) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white))),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddClientSheet(onCreated: () => _fetchClients(refresh: true)),
    );
  }

  void _showEditSheet(AdminUserModel user) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditClientSheet(user: user, onUpdated: () => _fetchClients(refresh: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: _SearchBarLive(controller: _searchCtrl, hint: 'Search clients...')),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _fetchClients(refresh: true),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
              ),
            ),
          ]).animate().fadeIn(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? _LoadingShimmer(color: AppColors.adminColor)
              : _errorMsg != null
              ? _ErrorState(message: _errorMsg!, onRetry: () => _fetchClients(refresh: true))
              : _filtered.isEmpty
              ? _EmptyState(label: 'clients')
              : RefreshIndicator(
            onRefresh: () => _fetchClients(refresh: true),
            color: AppColors.adminColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailPage(
                          userId: c.id,
                          initial: c,
                          accentColor: AppColors.adminColor,
                          onChanged: () => _fetchClients(refresh: true),
                        ),
                      ),
                    ),
                    child: CommonCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.adminColor.withOpacity(0.15),
                            child: Text(c.initial, style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.adminColor, fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(c.email, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  if (c.companyName != null && c.companyName!.isNotEmpty)
                                    _Tag(c.companyName!, AppColors.info),
                                  if (c.displayBudget.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    _Tag(c.displayBudget, AppColors.success),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              // Edit icon
                              GestureDetector(
                                onTap: () => _showEditSheet(c),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.adminColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.adminColor.withOpacity(0.25)),
                                  ),
                                  child: const Icon(Icons.edit_outlined, size: 15, color: AppColors.adminColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Delete icon
                              GestureDetector(
                                onTap: () => _deleteClient(c),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.error.withOpacity(0.25)),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: CommonButton(label: '+ Add Client', gradient: AppColors.adminGradient, onTap: _showAddSheet),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// ADD CLIENT SHEET
// ─────────────────────────────────────────
class _AddClientSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddClientSheet({required this.onCreated});
  @override
  State<_AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<_AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _projectTitleCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _gstNumberCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _apiService = ApiService();

  // Connected devices / platforms multi-select
  final Set<String> _selectedPlatforms = {};
  String? _platformError;

  static const List<_PlatformOption> _platformOptions = [
    _PlatformOption('youtube', 'YouTube', Icons.play_circle_fill_rounded, Color(0xFFFF0000)),
    _PlatformOption('pinterest', 'Pinterest', Icons.push_pin_rounded, Color(0xFFE60023)),
    _PlatformOption('twitter', 'Twitter', Icons.alternate_email_rounded, Color(0xFF1DA1F2)),
    _PlatformOption('facebook', 'Facebook', Icons.facebook_rounded, Color(0xFF1877F2)),
    _PlatformOption('instagram', 'Instagram', Icons.camera_alt_rounded, Color(0xFFE1306C)),
    _PlatformOption('threads', 'Threads', Icons.tag_rounded, Color(0xFF000000)),
  ];

  void _togglePlatform(String key) {
    setState(() {
      if (_selectedPlatforms.contains(key)) {
        _selectedPlatforms.remove(key);
      } else {
        _selectedPlatforms.add(key);
      }
      if (_selectedPlatforms.isNotEmpty) _platformError = null;
    });
  }

  void _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _platformError = _selectedPlatforms.isEmpty ? 'Select at least one platform' : null);
    if (!formValid || _selectedPlatforms.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.post(AppConstants.createUser, body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'role': 'Client',
        'budget': _budgetCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'projectTitle': _projectTitleCtrl.text.trim(),
        'duration': _durationCtrl.text.trim(),
        'gstNumber': _gstNumberCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'platforms': _selectedPlatforms.toList(),
      });

      // Try to pull the newly created client's id out of the response so we
      // can immediately check/generate their invoice via
      // GET /api/admin/invoices/:clientId
      final clientId = _extractClientId(res);
      final clientName = _nameCtrl.text.trim();

      if (mounted) {
        Navigator.pop(context); // close the "Add Client" sheet
        widget.onCreated();     // refresh the clients list behind it

        if (clientId != null && clientId.isNotEmpty) {
          // Show a small progress dialog that fetches/generates the invoice
          // for the client we just created, then reports success in the UI.
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ClientInvoiceStatusDialog(
              clientId: clientId,
              clientName: clientName,
              budget: _budgetCtrl.text.trim(),
            ),
          );
        } else {
          // Fallback: couldn't resolve a client id from the create response,
          // just show the normal success toast.
          final msg = (res['msg'] ?? res['message'] ?? 'Client created successfully').toString();
          _showSuccessSnack(context, msg);
        }
      }
    } catch (e) {
      setState(() { _errorMessage = _cleanErr(e.toString()); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Best-effort extraction of the created client's id from various possible
  /// response shapes returned by POST /api/user/create.
  String? _extractClientId(Map<String, dynamic> res) {
    dynamic pick(Map<String, dynamic> m) => m['_id'] ?? m['id'] ?? m['userId'] ?? m['clientId'];

    final data = res['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'] ?? data['client'];
      if (user is Map<String, dynamic>) {
        final id = pick(user);
        if (id != null) return id.toString();
      }
      final id = pick(data);
      if (id != null) return id.toString();
    }

    final user = res['user'] ?? res['client'];
    if (user is Map<String, dynamic>) {
      final id = pick(user);
      if (id != null) return id.toString();
    }

    final id = pick(res);
    return id?.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _companyCtrl.dispose(); _industryCtrl.dispose(); _budgetCtrl.dispose();
    _addressCtrl.dispose(); _projectTitleCtrl.dispose(); _durationCtrl.dispose();
    _gstNumberCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.adminGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add New Client', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Fill in client details below', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_errorMessage != null) _ErrorBanner(_errorMessage!),
                  if (_errorMessage != null) const SizedBox(height: 14),
                  _SheetField(label: 'Full Name *', hint: 'e.g. Alex Johnson', icon: Icons.person_rounded, controller: _nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Email Address *', hint: 'e.g. alex@email.com', icon: Icons.email_rounded, controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                  const SizedBox(height: 14),
                  _SheetPasswordField(controller: _passwordCtrl, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: (v) { if (v == null || v.trim().isEmpty) return 'Password is required'; if (v.length < 6) return 'Minimum 6 characters'; return null; }),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Phone Number', hint: 'e.g. 9876543210', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], maxLength: 10, validator: (v) => (v != null && v.trim().isNotEmpty && v.trim().length != 10) ? 'Enter a valid 10-digit number' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Company Name *', hint: 'e.g. Fashion Brand Co.', icon: Icons.business_rounded, controller: _companyCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Industry', hint: 'e.g. Fashion & Lifestyle', icon: Icons.category_rounded, controller: _industryCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Budget (INR) *', hint: 'e.g. 2500', icon: Icons.currency_rupee_rounded, controller: _budgetCtrl, keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Budget is required'; if (double.tryParse(v.trim()) == null) return 'Enter a valid amount'; return null; }),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Project Title', hint: 'e.g. Instagram Growth Campaign', icon: Icons.assignment_rounded, controller: _projectTitleCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Duration', hint: 'e.g. 3 months', icon: Icons.calendar_month_rounded, controller: _durationCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'GST Number', hint: 'e.g. 22AAAAA0000A1Z5', icon: Icons.receipt_long_rounded, controller: _gstNumberCtrl),
                  const SizedBox(height: 14),
                  _SheetMultiSelect(
                    label: 'Connected Devices *',
                    options: _platformOptions,
                    selected: _selectedPlatforms,
                    onToggle: _togglePlatform,
                    errorText: _platformError,
                  ),
                  const SizedBox(height: 24),
                  _isLoading ? _LoadingButton(gradient: AppColors.adminGradient) : CommonButton(label: 'Create Client', gradient: AppColors.adminGradient, onTap: _submit),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Text('Cancel', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// EDIT CLIENT SHEET
// ─────────────────────────────────────────
class _EditClientSheet extends StatefulWidget {
  final AdminUserModel user;
  final VoidCallback onUpdated;
  const _EditClientSheet({required this.user, required this.onUpdated});
  @override
  State<_EditClientSheet> createState() => _EditClientSheetState();
}

class _EditClientSheetState extends State<_EditClientSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _projectTitleCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _gstNumberCtrl;
  bool _isLoading = false;
  String? _errorMessage;
  final _apiService = ApiService();

  // Connected devices / platforms multi-select
  late final Set<String> _selectedPlatforms;
  String? _platformError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _companyCtrl = TextEditingController(text: widget.user.companyName ?? '');
    _industryCtrl = TextEditingController(text: widget.user.industry ?? '');
    _budgetCtrl = TextEditingController(text: widget.user.budget ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _projectTitleCtrl = TextEditingController(text: widget.user.projectTitle ?? '');
    _durationCtrl = TextEditingController(text: widget.user.duration ?? '');
    _gstNumberCtrl = TextEditingController(text: widget.user.gstNumber ?? '');
    _selectedPlatforms = {...widget.user.platform};
  }

  void _togglePlatform(String key) {
    setState(() {
      if (_selectedPlatforms.contains(key)) {
        _selectedPlatforms.remove(key);
      } else {
        _selectedPlatforms.add(key);
      }
      if (_selectedPlatforms.isNotEmpty) _platformError = null;
    });
  }

  void _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _platformError = _selectedPlatforms.isEmpty ? 'Select at least one platform' : null);
    if (!formValid || _selectedPlatforms.isEmpty) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.put(
        '${AppConstants.adminDeleteUser}/${widget.user.id}',
        body: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': 'Client',
          'budget': _budgetCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'projectTitle': _projectTitleCtrl.text.trim(),
          'duration': _durationCtrl.text.trim(),
          'gstNumber': _gstNumberCtrl.text.trim(),
          'phoneNumber': _phoneCtrl.text.trim(),
          'companyName': _companyCtrl.text.trim(),
          'industry': _industryCtrl.text.trim(),
          'platforms': _selectedPlatforms.toList(),
        },
      );
      final msg = (res['msg'] ?? res['message'] ?? 'Client updated successfully').toString();
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        _showSuccessSnack(context, msg);
      }
    } catch (e) {
      setState(() { _errorMessage = _cleanErr(e.toString()); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _companyCtrl.dispose(); _industryCtrl.dispose(); _budgetCtrl.dispose(); _addressCtrl.dispose();
    _projectTitleCtrl.dispose(); _durationCtrl.dispose(); _gstNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.adminGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Client', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Update client information', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_errorMessage != null) _ErrorBanner(_errorMessage!),
                  if (_errorMessage != null) const SizedBox(height: 14),
                  _SheetField(label: 'Full Name *', hint: 'e.g. Alex Johnson', icon: Icons.person_rounded, controller: _nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Email Address *', hint: 'e.g. alex@email.com', icon: Icons.email_rounded, controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Phone Number', hint: 'e.g. 9876543210', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], maxLength: 10, validator: (v) => (v != null && v.trim().isNotEmpty && v.trim().length != 10) ? 'Enter a valid 10-digit number' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Company Name *', hint: 'e.g. Fashion Brand Co.', icon: Icons.business_rounded, controller: _companyCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Industry', hint: 'e.g. Fashion & Lifestyle', icon: Icons.category_rounded, controller: _industryCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Monthly Budget (INR)', hint: 'e.g. 2500', icon: Icons.attach_money_rounded, controller: _budgetCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Project Title', hint: 'e.g. Instagram Growth Campaign', icon: Icons.assignment_rounded, controller: _projectTitleCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Duration', hint: 'e.g. 3 months', icon: Icons.calendar_month_rounded, controller: _durationCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'GST Number', hint: 'e.g. 22AAAAA0000A1Z5', icon: Icons.receipt_long_rounded, controller: _gstNumberCtrl),
                  const SizedBox(height: 14),
                  _SheetMultiSelect(
                    label: 'Connected Devices *',
                    options: _AddClientSheetState._platformOptions,
                    selected: _selectedPlatforms,
                    onToggle: _togglePlatform,
                    errorText: _platformError,
                  ),
                  const SizedBox(height: 24),
                  _isLoading ? _LoadingButton(gradient: AppColors.adminGradient) : CommonButton(label: 'Update Client', gradient: AppColors.adminGradient, onTap: _submit),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Text('Cancel', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TEAM PAGE  — real API (SMM + Designers)
// ─────────────────────────────────────────
class AdminTeamPage extends StatefulWidget {
  const AdminTeamPage({super.key});
  @override
  State<AdminTeamPage> createState() => _AdminTeamPageState();
}

class _AdminTeamPageState extends State<AdminTeamPage> {
  final _apiService = ApiService();
  final _searchCtrl = TextEditingController();

  List<AdminUserModel> _smm = [];
  List<AdminUserModel> _designers = [];
  List<AdminUserModel> _allFiltered = [];
  bool _isLoadingSmm = true;
  bool _isLoadingDesigners = true;
  String? _errorMsg;
  String _selectedFilter = 'All';

  bool get _isLoading => _isLoadingSmm || _isLoadingDesigners;

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applySearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll({bool refresh = false}) async {
    setState(() { _isLoadingSmm = true; _isLoadingDesigners = true; _errorMsg = null; });
    await Future.wait([_fetchSmm(), _fetchDesigners()]);
    _applySearch();
  }

  Future<void> _fetchSmm() async {
    try {
      final res = await _apiService.get(AppConstants.adminSmm, queryParams: {'page': '1', 'limit': '50'});
      final dataMap = res['data'];
      final raw = (dataMap is Map ? (dataMap['smms'] ?? dataMap['users'] ?? dataMap['smm']) : null)
          ?? res['users'] ?? res['smm'] ?? res['data'] ?? [];
      _smm = (raw is List ? raw : []).whereType<Map<String, dynamic>>().map(AdminUserModel.fromJson).toList();
    } catch (e) {
      _errorMsg = _cleanErr(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingSmm = false);
    }
  }

  Future<void> _fetchDesigners() async {
    try {
      final res = await _apiService.get(AppConstants.adminGraphicDesigners, queryParams: {'page': '1', 'limit': '50'});
      final dataMap = res['data'];
      final raw = (dataMap is Map ? (dataMap['designers'] ?? dataMap['graphic_designers'] ?? dataMap['users']) : null)
          ?? res['users'] ?? res['designers'] ?? res['data'] ?? [];
      _designers = (raw is List ? raw : []).whereType<Map<String, dynamic>>().map(AdminUserModel.fromJson).toList();
    } catch (e) {
      _errorMsg ??= _cleanErr(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingDesigners = false);
    }
  }

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<AdminUserModel> base;
    switch (_selectedFilter) {
      case 'SMM':       base = _smm;       break;
      case 'Designers': base = _designers; break;
      default:          base = [..._smm, ..._designers];
    }
    setState(() {
      _allFiltered = q.isEmpty
          ? base
          : base.where((u) =>
      u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          (u.phone ?? '').contains(q) ||
          (u.specialization ?? '').toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _deleteMember(AdminUserModel user) async {
    final ok = await _showDeleteDialog(context, user.name, user.email);
    if (!ok || !mounted) return;
    try {
      final res = await _apiService.delete('${AppConstants.adminDeleteUser}/${user.id}');
      final msg = (res['msg'] ?? res['message'] ?? 'Member deleted successfully').toString();
      setState(() {
        _smm.removeWhere((u) => u.id == user.id);
        _designers.removeWhere((u) => u.id == user.id);
      });
      _applySearch();
      if (mounted) _snack(msg, false);
    } catch (e) {
      if (mounted) _snack(_cleanErr(e.toString()), true);
    }
  }

  void _snack(String msg, bool isError) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white))),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );

  void _showAddSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddMemberSheet(onCreated: () => _fetchAll(refresh: true)),
    );
  }

  void _showEditSheet(AdminUserModel user) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _EditMemberSheet(user: user, onUpdated: () => _fetchAll(refresh: true)),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SMM': return AppColors.smmColor;
      case 'Graphic Designer': return AppColors.designerColor;
      case 'Developer': return AppColors.info;
      case 'Support': return AppColors.accent;
      default: return AppColors.warning;
    }
  }

  String _roleLabel(String role) {
    const labels = {
      'SMM': 'Social Media Manager',
      'Graphic Designer': 'Graphic Designer',
      'Video Editor': 'Video Editor',
      'Content Writer': 'Content Writer',
      'Developer': 'Developer',
      'Support': 'Support Executive',
      'SEO Specialist': 'SEO Specialist',
    };
    return labels[role] ?? role;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: _SearchBarLive(controller: _searchCtrl, hint: 'Search team...')),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _fetchAll(refresh: true),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
              ),
            ),
          ]).animate().fadeIn(),
        ),
        const SizedBox(height: 8),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: ['All', 'SMM', 'Designers'].map((t) {
              final sel = _selectedFilter == t;
              return GestureDetector(
                onTap: () { setState(() => _selectedFilter = t); _applySearch(); },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.adminGradient : null,
                      color: sel ? null : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: sel ? null : Border.all(color: AppColors.border),
                    ),
                    child: Text(t, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate(delay: 80.ms).fadeIn(),
        Expanded(
          child: _isLoading
              ? _LoadingShimmer(color: AppColors.adminColor)
              : _errorMsg != null
              ? _ErrorState(message: _errorMsg!, onRetry: () => _fetchAll(refresh: true))
              : _allFiltered.isEmpty
              ? _EmptyState(label: 'team members')
              : RefreshIndicator(
            onRefresh: () => _fetchAll(refresh: true),
            color: AppColors.adminColor,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _allFiltered.length,
              itemBuilder: (_, i) {
                final m = _allFiltered[i];
                final col = _roleColor(m.role);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminUserDetailPage(
                          userId: m.id,
                          initial: m,
                          accentColor: col,
                          onChanged: () => _fetchAll(refresh: true),
                        ),
                      ),
                    ),
                    child: CommonCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(color: col.withOpacity(0.15), shape: BoxShape.circle),
                            child: Center(child: Text(m.initial, style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: col, fontSize: 16))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(_roleLabel(m.role), style: GoogleFonts.sora(fontSize: 11, color: col, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(m.email, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                                if (m.specialization != null && m.specialization!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(m.specialization!, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showEditSheet(m),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: col.withOpacity(0.25))),
                                  child: Icon(Icons.edit_outlined, size: 15, color: col),
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _deleteMember(m),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error.withOpacity(0.25))),
                                  child: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: CommonButton(label: '+ Add Member', gradient: AppColors.adminGradient, onTap: _showAddSheet),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// ADD MEMBER SHEET
// ─────────────────────────────────────────
class _AddMemberSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _AddMemberSheet({required this.onCreated});
  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  String _selectedRole = 'SMM';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _apiService = ApiService();

  final _roles = {
    'SMM': 'Social Media Manager',
    'Graphic Designer': 'Graphic Designer',
    'Video Editor': 'Video Editor',
    'Content Writer': 'Content Writer',
    'Developer': 'Developer',
    'Support': 'Support Executive',
    'SEO Specialist': 'SEO Specialist',
  };

  Color get _roleColor {
    switch (_selectedRole) {
      case 'SMM': return AppColors.smmColor;
      case 'Graphic Designer': return AppColors.designerColor;
      case 'Developer': return AppColors.info;
      case 'Support': return AppColors.accent;
      default: return AppColors.warning;
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.post(AppConstants.createUser, body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'role': _selectedRole,
        'address': _addressCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'specialization': _specializationCtrl.text.trim(),
        'experience': _experienceCtrl.text.trim(),
      });
      final msg = (res['msg'] ?? res['message'] ?? 'Team member created successfully').toString();
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        _showSuccessSnack(context, msg);
      }
    } catch (e) {
      setState(() { _errorMessage = _cleanErr(e.toString()); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passwordCtrl.dispose(); _addressCtrl.dispose(); _specializationCtrl.dispose();_experienceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.adminGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add Team Member', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Fill in member details below', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_errorMessage != null) _ErrorBanner(_errorMessage!),
                  if (_errorMessage != null) const SizedBox(height: 14),
                  _SheetField(label: 'Full Name *', hint: 'e.g. John Manager', icon: Icons.person_rounded, controller: _nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Email Address *', hint: 'e.g. john@agency.com', icon: Icons.email_rounded, controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                  const SizedBox(height: 14),
                  _SheetPasswordField(controller: _passwordCtrl, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: (v) { if (v == null || v.trim().isEmpty) return 'Password is required'; if (v.length < 6) return 'Minimum 6 characters'; return null; }),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Phone Number *', hint: 'e.g. 9876543210', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], maxLength: 10, validator: (v) { if (v == null || v.trim().isEmpty) return 'Phone is required'; if (v.trim().length != 10) return 'Enter a valid 10-digit number'; return null; }),
                  const SizedBox(height: 14),
                  _SheetDropdown(label: 'Role *', icon: Icons.work_rounded, value: _selectedRole, items: _roles.keys.toList(), displayLabels: _roles, onChanged: (v) => setState(() => _selectedRole = v!)),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Specialization', hint: 'e.g. Instagram Growth, Brand Design', icon: Icons.star_rounded, controller: _specializationCtrl),
                  _SheetField(label: 'Experience', hint: '2 year', icon: Icons.work, controller: _experienceCtrl),
                  const SizedBox(height: 14),
                  // _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
                  const SizedBox(height: 20),
                  // Role preview badge
                  // Container(
                  //   padding: const EdgeInsets.all(14),
                  //   decoration: BoxDecoration(color: _roleColor.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _roleColor.withOpacity(0.25))),
                  //   child: Row(children: [
                  //     Container(
                  //       width: 36, height: 36,
                  //       decoration: BoxDecoration(color: _roleColor.withOpacity(0.15), shape: BoxShape.circle),
                  //       child: Center(child: Text(_nameCtrl.text.isEmpty ? '?' : _nameCtrl.text[0].toUpperCase(), style: GoogleFonts.sora(color: _roleColor, fontWeight: FontWeight.w700, fontSize: 14))),
                  //     ),
                  //     const SizedBox(width: 12),
                  //     Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  //       Text(_nameCtrl.text.isEmpty ? 'Member Name' : _nameCtrl.text, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  //       Text(_roles[_selectedRole] ?? _selectedRole, style: GoogleFonts.sora(fontSize: 11, color: _roleColor, fontWeight: FontWeight.w500)),
                  //     ]),
                  //   ]),
                  // ),
                  const SizedBox(height: 20),
                  _isLoading ? _LoadingButton(gradient: AppColors.adminGradient) : CommonButton(label: 'Create Member', gradient: AppColors.adminGradient, onTap: _submit),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Text('Cancel', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// EDIT MEMBER SHEET
// ─────────────────────────────────────────
class _EditMemberSheet extends StatefulWidget {
  final AdminUserModel user;
  final VoidCallback onUpdated;
  const _EditMemberSheet({required this.user, required this.onUpdated});
  @override
  State<_EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends State<_EditMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _specializationCtrl;
  bool _isLoading = false;
  String? _errorMessage;
  final _apiService = ApiService();

  final _roles = {
    'SMM': 'Social Media Manager',
    'Graphic Designer': 'Graphic Designer',
    'Video Editor': 'Video Editor',
    'Content Writer': 'Content Writer',
    'Developer': 'Developer',
    'Support': 'Support Executive',
    'SEO Specialist': 'SEO Specialist',
  };

  Color get _roleColor {
    switch (widget.user.role) {
      case 'SMM': return AppColors.smmColor;
      case 'Graphic Designer': return AppColors.designerColor;
      case 'Developer': return AppColors.info;
      case 'Support': return AppColors.accent;
      default: return AppColors.warning;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _specializationCtrl = TextEditingController(text: widget.user.specialization ?? '');
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.put(
        '${AppConstants.adminDeleteUser}/${widget.user.id}',
        body: {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': widget.user.role,
          'address': _addressCtrl.text.trim(),
          'phoneNumber': _phoneCtrl.text.trim(),
          'specialization': _specializationCtrl.text.trim(),
        },
      );
      final msg = (res['msg'] ?? res['message'] ?? 'Member updated successfully').toString();
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        _showSuccessSnack(context, msg);
      }
    } catch (e) {
      setState(() { _errorMessage = _cleanErr(e.toString()); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _specializationCtrl.dispose();
    super.dispose();
  }

  String _specializationHint(String role) {
    switch (role) {
      case 'SMM': return 'e.g. Instagram Growth, Paid Ads';
      case 'Graphic Designer': return 'e.g. Brand Design, Motion Graphics';
      case 'SEO Specialist': return 'e.g. On-Page SEO, Link Building';
      case 'Video Editor': return 'e.g. Reels, Short-form Content';
      case 'Content Writer': return 'e.g. Blog, Copywriting';
      default: return 'e.g. Your area of expertise';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final roleLabel = _roles[widget.user.role] ?? widget.user.role;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28)), border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.adminGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Edit $roleLabel', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Update member information', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(roleLabel, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor)),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_errorMessage != null) _ErrorBanner(_errorMessage!),
                  if (_errorMessage != null) const SizedBox(height: 14),
                  _SheetField(label: 'Full Name *', hint: 'e.g. John Manager', icon: Icons.person_rounded, controller: _nameCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Email Address *', hint: 'e.g. john@agency.com', icon: Icons.email_rounded, controller: _emailCtrl, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; }),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Phone Number', hint: 'e.g. 9876543210', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], maxLength: 10, validator: (v) => (v != null && v.trim().isNotEmpty && v.trim().length != 10) ? 'Enter a valid 10-digit number' : null),
                  const SizedBox(height: 14),
                  if (['SMM', 'Graphic Designer', 'SEO Specialist', 'Video Editor', 'Content Writer'].contains(widget.user.role)) ...[
                    _SheetField(label: 'Specialization', hint: _specializationHint(widget.user.role), icon: Icons.star_rounded, controller: _specializationCtrl),
                    const SizedBox(height: 14),
                  ],
                  // _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
                  const SizedBox(height: 24),
                  _isLoading ? _LoadingButton(gradient: AppColors.adminGradient) : CommonButton(label: 'Update Member', gradient: AppColors.adminGradient, onTap: _submit),
                  const SizedBox(height: 8),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Center(child: Text('Cancel', style: GoogleFonts.sora(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)))),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ADMIN PROJECTS PAGE  (unchanged – static)
// ─────────────────────────────────────────
class AdminProjectsPage extends StatelessWidget {
  const AdminProjectsPage({super.key});

  static const _projects = [
    _Project('Fashion Brand Campaign', 'Instagram, Facebook', 0.75, 'Active', AppColors.designerColor),
    _Project('Tech Product Launch', 'LinkedIn, Twitter', 0.60, 'Active', AppColors.smmColor),
    _Project('Summer Sale Campaign', 'All Platforms', 0.90, 'Completed', AppColors.success),
    _Project('Food Restaurant Promo', 'Instagram', 0.30, 'Active', AppColors.warning),
    _Project('Travel Agency', 'Facebook, Instagram', 0.50, 'On Hold', AppColors.textMuted),
    _Project('Fitness Brand', 'All Platforms', 0.85, 'Active', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: _SearchBar('Search projects...')),
            const SizedBox(width: 10),
            _FilterBtn(),
          ]).animate().fadeIn(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _projects.length,
            itemBuilder: (_, i) {
              final p = _projects[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommonCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(p.name, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        _StatusBadge(p.status),
                      ]),
                      const SizedBox(height: 4),
                      Text(p.platforms, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: p.progress, backgroundColor: AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(p.color), minHeight: 6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(p.progress * 100).toInt()}%', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: p.color)),
                      ]),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: CommonButton(label: '+ New Project', gradient: AppColors.adminGradient, onTap: () {}),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// ADMIN REPORTS PAGE  (unchanged – static)
// ─────────────────────────────────────────
class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final reportStats = [
    //   ('Total Projects', '76', '+11.2%', AppColors.adminColor, Icons.folder_rounded),
    //   ('Completed Projects', '42', '+14.8%', AppColors.success, Icons.check_circle_rounded),
    //   ('Pending Projects', '18', '+5.5%', AppColors.warning, Icons.pending_rounded),
    //   ('Cancelled Projects', '6', '-2.1%', AppColors.error, Icons.cancel_rounded),
    // ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reports Overview', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Text('This Month', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 16),
                ]),
              ),
            ],
          ).animate().fadeIn(),
          // const SizedBox(height: 16),
          // ...List.generate(reportStats.length, (i) {
          //   final s = reportStats[i];
          //   return Padding(
          //     padding: const EdgeInsets.only(bottom: 10),
          //     child: CommonCard(
          //       padding: const EdgeInsets.all(16),
          //       child: Row(children: [
          //         Container(width: 46, height: 46, decoration: BoxDecoration(color: s.$4.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(s.$5, color: s.$4, size: 22)),
          //         const SizedBox(width: 14),
          //         Expanded(child: Text(s.$1, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          //         Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          //           Text(s.$2, style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          //           Text(s.$3, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: s.$3.startsWith('-') ? AppColors.error : AppColors.success)),
          //         ]),
          //       ]),
          //     ).animate(delay: Duration(milliseconds: 80 * i)).fadeIn(),
          //   );
          // }),
          const SizedBox(height: 16),
          CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Overview', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('\$24,850', style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.adminColor)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [0.4, 0.6, 0.5, 0.75, 0.55, 0.8, 0.65, 0.9, 0.7, 0.85, 0.75, 1.0].asMap().entries.map((e) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 80 * e.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.adminColor, AppColors.adminColor.withOpacity(0.3)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].map((m) => Text(m, style: GoogleFonts.sora(fontSize: 9, color: AppColors.textMuted))).toList(),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),
          // const SizedBox(height: 16),
          // CommonCard(
          //   gradient: AppColors.adminGradient,
          //   child: Row(children: [
          //     const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          //     const SizedBox(width: 14),
          //     Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          //       Text('Top Performing Manager', style: GoogleFonts.sora(fontSize: 12, color: Colors.white70)),
          //       const SizedBox(height: 4),
          //       Text('John Manager', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          //       Text('85% performance score', style: GoogleFonts.sora(fontSize: 11, color: Colors.white70)),
          //     ]),
          //   ]),
          // ).animate(delay: 500.ms).fadeIn(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// ─────────────────────────────────────────
// SHARED INVOICE HELPERS
// Used by both the "client created" dialog below and the invoices section
// on the client detail page (AdminUserDetailPage), so parsing + downloading
// behave identically everywhere invoices are shown.
// ─────────────────────────────────────────
List<Map<String, dynamic>> parseInvoiceList(Map<String, dynamic> res) {
  dynamic node = res['data'] ?? res['invoices'] ?? res;
  if (node is Map<String, dynamic> && node['invoices'] != null) node = node['invoices'];
  if (node is! List) {
    // Backend returned a single invoice object instead of a list.
    if (node is Map<String, dynamic>) node = [node];
    else node = [];
  }
  return node.whereType<Map<String, dynamic>>().toList();
}

String? invoiceField(Map<String, dynamic> node, List<String> keys) {
  for (final k in keys) {
    final v = node[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return null;
}

String? invoiceFileUrl(Map<String, dynamic> node) {
  final rawUrl = invoiceField(node, [
    'pdfUrl', 'invoiceUrl', 'fileUrl', 'downloadUrl', 'receiptUrl', 'url',
    'invoicePdf', 'invoicePath', 'filePath', 'path', 'attachment', 'file', 'link',
  ]);
  if (rawUrl == null) {
    // Nothing matched our known key names — dump the raw keys so it's easy
    // to spot the actual field name the backend used and add it above.
    debugPrint('[invoice] no file-url field found on invoice node. keys=${node.keys.toList()}');
    return null;
  }
  return rawUrl.startsWith('http')
      ? rawUrl
      : '${AppConstants.baseUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
}

/// Downloads the invoice PDF and opens it locally. Returns an error message
/// on failure, or null on success.
///
/// This intentionally does NOT fall back to url_launcher / an external
/// browser tab. Two things break that approach on this backend:
///  1. The API base URL is a free ngrok tunnel, and free tunnels show an
///     interstitial "You are about to visit..." warning page to any request
///     that doesn't send the `ngrok-skip-browser-warning` header. Our Dio
///     client sends that header (see DioClient), but a plain browser tab
///     does not — so the "download" just opens a warning page instead of
///     the PDF.
///  2. The invoice endpoint likely requires the admin's auth token too,
///     which an external browser tab also won't have.
/// So the download always goes through ApiService's Dio instance (which
/// attaches the auth token + ngrok header) and the file is saved + opened
/// purely with Flutter packages: path_provider (find a writable app
/// directory) + open_filex (open the saved PDF). If that fails, we surface
/// the error instead of silently opening an external link.
Future<String?> downloadInvoicePdf({required String url, required String invoiceId}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final safeId = invoiceId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final savePath = '${dir.path}/invoice_$safeId.pdf';

    await ApiService.rawDio.download(url, savePath);

    final result = await OpenFilex.open(savePath);
    if (result.type != ResultType.done) {
      return 'Downloaded, but could not open the file (${result.message}).';
    }
    return null;
  } catch (e) {
    return 'Could not download the invoice. Please try again.';
  }
}

// CLIENT CREATED → INVOICE STATUS DIALOG
// Shown right after a client is created.
// 1) POST /api/admin/invoices   body: { clientId, items: [{ rate }] }
//    → generates the invoice. `rate` = the Budget (INR) entered on the
//    Add Client sheet, forwarded through as the invoice line item's rate.
// 2) GET  /api/admin/invoices/client/:clientId     → fetches all invoices
//    for this client and renders them as a list right below, in this dialog.
// ─────────────────────────────────────────
class _ClientInvoiceStatusDialog extends StatefulWidget {
  final String clientId;
  final String clientName;
  // Budget entered on the "Add Client" sheet — sent to the invoice-generate
  // API as the rate of the (single) invoice line item.
  final String? budget;
  const _ClientInvoiceStatusDialog({required this.clientId, required this.clientName, this.budget});

  @override
  State<_ClientInvoiceStatusDialog> createState() => _ClientInvoiceStatusDialogState();
}

class _ClientInvoiceStatusDialogState extends State<_ClientInvoiceStatusDialog> {
  final _apiService = ApiService();

  bool _isLoadingInvoice = true;
  bool _invoiceFailed = false;
  String? _errorMessage;

  // List of invoices for this client (GET /api/admin/invoices/client/:clientId)
  List<Map<String, dynamic>> _invoices = [];
  bool _isOpeningDownload = false;
  String? _downloadingInvoiceId;

  @override
  void initState() {
    super.initState();
    _generateAndFetchInvoices();
  }

  // Step A: POST /api/admin/invoices
  // body: { clientId, items: [{ rate }] } → generate invoice
  // The "rate" is the Budget (INR) value entered on the Add Client sheet —
  // that's what goes into the invoice's single line item as its rate.
  Future<void> _generateInvoice() async {
    await _apiService.post(AppConstants.adminInvoices, body: {
      'clientId': widget.clientId,
      'items': [
        {
          'rate': widget.budget ?? '',
        },
      ],
    });
  }

  // Step B: GET /api/admin/invoices/client/:clientId → list all invoices
  Future<void> _fetchInvoiceList() async {
    final res = await _apiService.get('${AppConstants.adminInvoicesByClient}/${widget.clientId}');
    _parseInvoiceList(res);
  }

  Future<void> _generateAndFetchInvoices() async {
    try {
      await _generateInvoice();
    } catch (e) {
      // Generation failing shouldn't block showing already-existing invoices,
      // so we swallow it here and let the list fetch decide the final state.
    }
    try {
      await _fetchInvoiceList();
      if (mounted) setState(() => _isLoadingInvoice = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInvoice = false;
          _invoiceFailed = true;
          _errorMessage = _cleanErr(e.toString());
        });
      }
    }
  }

  void _parseInvoiceList(Map<String, dynamic> res) {
    _invoices = parseInvoiceList(res);
  }

  String? _invoiceField(Map<String, dynamic> node, List<String> keys) => invoiceField(node, keys);

  String? _invoiceFileUrl(Map<String, dynamic> node) => invoiceFileUrl(node);

  Future<void> _downloadInvoice(String url, String invoiceId) async {
    setState(() {
      _isOpeningDownload = true;
      _downloadingInvoiceId = invoiceId;
    });
    final err = await downloadInvoicePdf(url: url, invoiceId: invoiceId);
    if (mounted) {
      if (err != null) _showSuccessSnack(context, err);
      setState(() {
        _isOpeningDownload = false;
        _downloadingInvoiceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(gradient: AppColors.adminGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Client Added', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(widget.clientName, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
            const SizedBox(height: 20),

            // Step 1 — client created (always done, we're here because it succeeded)
            _InvoiceStepRow(
              done: true,
              loading: false,
              failed: false,
              title: 'Client account created',
              subtitle: 'Login credentials generated',
            ),
            const SizedBox(height: 12),

            // Step 2 — invoice generation (POST /api/admin/invoices, body: clientId)
            // + list fetch (GET /api/admin/invoices/client/:clientId)
            _InvoiceStepRow(
              done: !_isLoadingInvoice && !_invoiceFailed,
              loading: _isLoadingInvoice,
              failed: _invoiceFailed,
              title: _isLoadingInvoice
                  ? 'Generating invoice…'
                  : (_invoiceFailed ? 'Invoice generation pending' : 'Invoice generated'),
              subtitle: _isLoadingInvoice
                  ? 'Fetching invoices for this client'
                  : (_invoiceFailed
                  ? (_errorMessage ?? 'Could not confirm invoice yet')
                  : 'Invoice(s) ready for this client'),
            ),

            if (!_isLoadingInvoice && !_invoiceFailed) ...[
              const SizedBox(height: 16),
              if (_invoices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Text('Invoice generated successfully for this client.',
                      style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final node = _invoices[index];
                      final invoiceId = _invoiceField(node, ['invoiceNumber', 'invoiceNo', 'number', '_id', 'id']);
                      final amount = _invoiceField(node, ['totalAmount', 'amount', 'total']);
                      final status = _invoiceField(node, ['status']) ?? 'generated';
                      final date = _invoiceField(node, ['createdAt', 'date', 'issueDate']);
                      final fileUrl = _invoiceFileUrl(node);
                      final isDownloadingThis = _isOpeningDownload && _downloadingInvoiceId == (invoiceId ?? '$index');

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.receipt_long_rounded, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Text('Invoice Details', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                          ]),
                          const SizedBox(height: 8),
                          if (invoiceId != null) _InvoiceDetailLine('Invoice No.', invoiceId),
                          if (amount != null) _InvoiceDetailLine('Amount', '\$${amount}'),
                          _InvoiceDetailLine('Status', status),
                          if (date != null) _InvoiceDetailLine('Date', date),
                          if (fileUrl != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _isOpeningDownload ? null : () => _downloadInvoice(fileUrl, invoiceId ?? '$index'),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: isDownloadingThis
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.success))
                                      : Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.download_rounded, color: AppColors.success, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Download Invoice', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 20),
            CommonButton(
              label: _isLoadingInvoice ? 'Please wait…' : 'Done',
              gradient: AppColors.adminGradient,
              onTap: _isLoadingInvoice ? () {} : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceStepRow extends StatelessWidget {
  final bool done;
  final bool loading;
  final bool failed;
  final String title;
  final String subtitle;
  const _InvoiceStepRow({required this.done, required this.loading, required this.failed, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final Color iconColor = failed ? AppColors.warning : (done ? AppColors.success : AppColors.textSecondary);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 24, height: 24,
        child: loading
            ? const CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.success)
            : Icon(
          failed ? Icons.error_outline_rounded : (done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
          color: iconColor,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    ]);
  }
}

class _InvoiceDetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceDetailLine(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────

String _cleanErr(String raw) =>
    raw.contains(': ') ? raw.substring(raw.indexOf(': ') + 2) : raw;

void _showSuccessSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white))),
    ]),
    backgroundColor: AppColors.success,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  ));
}

/// Shows confirmation dialog. Returns true if user pressed Delete.
Future<bool> _showDeleteDialog(BuildContext context, String name, String email) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
        ),
        const SizedBox(width: 12),
        Text('Delete User', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Are you sure you want to delete', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(email, style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('This action cannot be undone.', style: GoogleFonts.sora(fontSize: 12, color: AppColors.error)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel', style: GoogleFonts.sora(color: AppColors.textSecondary, fontSize: 14)),
        ),
        GestureDetector(
          onTap: () => Navigator.of(ctx).pop(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
            child: Text('Okay', style: GoogleFonts.sora(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 4),
      ],
    ),
  ) ??
      false;
}

// ─── Loading button ────────────────────────────────────────────────────────
class _LoadingButton extends StatelessWidget {
  final LinearGradient gradient;
  const _LoadingButton({required this.gradient});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))),
    );
  }
}

// ─── Error banner ──────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.3))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error))),
      ]),
    );
  }
}

// ─── Live search bar ───────────────────────────────────────────────────────
class _SearchBarLive extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SearchBarLive({required this.controller, required this.hint});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: controller,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.zero),
        )),
      ]),
    );
  }
}

// ─── Static search bar (projects page) ────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar(this.hint);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const SizedBox(width: 12),
        const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted), border: InputBorder.none, contentPadding: EdgeInsets.zero),
        )),
      ]),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  Color get _color {
    switch (status) {
      case 'Active': return AppColors.success;
      case 'On Hold': return AppColors.warning;
      case 'Completed': return AppColors.info;
      case 'Cancelled': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: _color)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Loading shimmer list ──────────────────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  final Color color;
  const _LoadingShimmer({required this.color});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 76,
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color))),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(color: color.withOpacity(0.05), duration: 1200.ms),
      ),
    );
  }
}

// ─── Error state ───────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 28)),
            const SizedBox(height: 16),
            Text('Something went wrong', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Text('Retry', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No $label found', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Try a different search term', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Form field ────────────────────────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const _SheetField({required this.label, required this.hint, required this.icon, required this.controller, this.keyboardType, this.validator, this.maxLines = 1, this.inputFormatters, this.maxLength});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          buildCounter: maxLength == null ? null : (_, {required currentLength, required isFocused, maxLength}) => null,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 17),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.adminColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─── Password field ────────────────────────────────────────────────────────
class _SheetPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _SheetPasswordField({required this.controller, required this.obscure, required this.onToggle, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password *', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Min. 6 characters',
            hintStyle: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 17),
            suffixIcon: GestureDetector(onTap: onToggle, child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMuted, size: 17)),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.adminColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown field ────────────────────────────────────────────────────────
class _SheetDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final Map<String, String>? displayLabels;
  final void Function(String?) onChanged;

  const _SheetDropdown({required this.label, required this.icon, required this.value, required this.items, required this.onChanged, this.displayLabels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.textPrimary),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Row(children: [
                  Icon(icon, color: AppColors.textMuted, size: 15),
                  const SizedBox(width: 8),
                  Flexible(child: Text(displayLabels?[item] ?? item, overflow: TextOverflow.ellipsis, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textPrimary))),
                ]),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Platform option (for connected devices multi-select) ──────────────────
class _PlatformOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _PlatformOption(this.key, this.label, this.icon, this.color);
}

// ─── Connected devices multi-select field ───────────────────────────────────
class _SheetMultiSelect extends StatelessWidget {
  final String label;
  final List<_PlatformOption> options;
  final Set<String> selected;
  final void Function(String key) onToggle;
  final String? errorText;

  const _SheetMultiSelect({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasError ? AppColors.error : AppColors.border, width: hasError ? 1.2 : 1),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = selected.contains(opt.key);
              return GestureDetector(
                onTap: () => onToggle(opt.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? opt.color.withOpacity(0.14) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? opt.color : AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt.icon, size: 15, color: isSelected ? opt.color : AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        opt.label,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? opt.color : AppColors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, size: 14, color: opt.color),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: GoogleFonts.sora(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────
// DATA MODELS  (local – for Projects page)
// ─────────────────────────────────────────
class _Project {
  final String name, platforms, status;
  final double progress;
  final Color color;
  const _Project(this.name, this.platforms, this.progress, this.status, this.color);
}
// ─────────────────────────────────────────
// USER DETAIL PAGE  — GET /api/admin/users/:id
// Shown when tapping a client or team-member card. Loads the full profile
// fresh from the API (the list-card data is used only as an instant
// placeholder while the real detail request is in flight).
// ─────────────────────────────────────────
class AdminUserDetailPage extends StatefulWidget {
  final String userId;
  final AdminUserModel initial;
  final Color accentColor;
  final VoidCallback onChanged;

  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.initial,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  final _apiService = ApiService();

  late AdminUserModel _user = widget.initial;
  Map<String, dynamic> _rawExtra = const {};
  String? _aboutText;
  bool _isLoading = true;
  String? _errorMsg;

  static const _aboutKeys = {'about', 'aboutme', 'bio', 'notes', 'description', 'summary'};

  bool get _isClient => _user.role.isEmpty || _user.role == 'Client';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final res = await _apiService.get('${AppConstants.adminUserDetail}/${widget.userId}');
      // Response shape is { success, msg, data: { user: {...} } } — dig past
      // both wrapper layers to reach the flat user object.
      dynamic raw = res['data'] ?? res;
      if (raw is Map && raw['user'] != null) raw = raw['user'];
      final json = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

      // Known fields go through the shared model; anything else present in
      // the response is kept around to render in "Additional Info" below —
      // but only if it actually has meaningful data. Internal/technical
      // fields and empty values (null, '', [], {}, false-only flags) are
      // dropped so the UI never shows blank rows.
      const known = {
        '_id', 'id', 'name', 'email', 'role', 'phoneNumber', 'phone',
        'companyName', 'industry', 'budget', 'address', 'specialization',
        'status', 'platform', 'platforms', '__v', 'password',
        'projectTitle', 'duration', 'gstNumber',
      };
      const internal = {
        'agencyId', 'createdByAdmin', 'loginSource', 'isActive',
        'deletedAt', 'resetOtp', 'resetOtpExpiry', 'resetOtpVerifiedAt',
      };
      final extra = <String, dynamic>{
        for (final entry in json.entries)
          if (!known.contains(entry.key) &&
              !internal.contains(entry.key) &&
              !_aboutKeys.contains(entry.key.toLowerCase()) &&
              !_isEmptyValue(entry.value))
            entry.key: entry.value,
      };
      final aboutEntry = json.entries.firstWhere(
            (e) => _aboutKeys.contains(e.key.toLowerCase()) && !_isEmptyValue(e.value),
        orElse: () => const MapEntry('', null),
      );

      setState(() {
        _user = json.isEmpty ? widget.initial : AdminUserModel.fromJson(json);
        _rawExtra = extra;
        _aboutText = aboutEntry.value?.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMsg = _cleanErr(e.toString()); _isLoading = false; });
    }
  }

  void _openEdit() {
    if (_isClient) {
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _EditClientSheet(
          user: _user,
          onUpdated: () { widget.onChanged(); _fetchDetail(); },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _EditMemberSheet(
          user: _user,
          onUpdated: () { widget.onChanged(); _fetchDetail(); },
        ),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await _showDeleteDialog(context, _user.name, _user.email);
    if (!ok || !mounted) return;
    try {
      final res = await _apiService.delete('${AppConstants.adminDeleteUser}/${_user.id}');
      final msg = (res['msg'] ?? res['message'] ?? 'Deleted successfully').toString();
      widget.onChanged();
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_cleanErr(e.toString()), style: GoogleFonts.sora(fontSize: 13, color: Colors.white)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isClient ? 'Client Details' : 'Team Member Details',
          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
        //     onPressed: _isLoading ? null : _openEdit,
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white),
        //     onPressed: _isLoading ? null : _delete,
        //   ),
        //   const SizedBox(width: 4),
        // ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: accent))
          : _errorMsg != null
          ? _ErrorState(message: _errorMsg!, onRetry: _fetchDetail)
          : RefreshIndicator(
        onRefresh: _fetchDetail,
        color: accent,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _DetailHeaderBanner(user: _user, accent: accent, isClient: _isClient),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuickContactCard(user: _user, accent: accent),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_aboutText != null && _aboutText!.trim().isNotEmpty) ...[
                    _AboutCard(text: _aboutText!.trim()),
                    const SizedBox(height: 14),
                  ],
                  _DetailSection(
                    title: 'Details',
                    accent: accent,
                    rows: [
                      if (_user.address != null && _user.address!.isNotEmpty)
                        _DetailRow(Icons.location_on_outlined, 'Address', _user.address!),
                      if (_isClient) ...[
                        if (_user.companyName != null && _user.companyName!.isNotEmpty)
                          _DetailRow(Icons.apartment_rounded, 'Company', _user.companyName!),
                        if (_user.industry != null && _user.industry!.isNotEmpty)
                          _DetailRow(Icons.category_outlined, 'Industry', _user.industry!),
                        if (_user.displayBudget.isNotEmpty)
                          _DetailRow(Icons.currency_rupee_rounded, 'Budget', _user.displayBudget),
                        if (_user.projectTitle != null && _user.projectTitle!.isNotEmpty)
                          _DetailRow(Icons.assignment_outlined, 'Project Title', _user.projectTitle!),
                        if (_user.duration != null && _user.duration!.isNotEmpty)
                          _DetailRow(Icons.calendar_month_outlined, 'Duration', _user.duration!),
                        if (_user.gstNumber != null && _user.gstNumber!.isNotEmpty)
                          _DetailRow(Icons.receipt_long_outlined, 'GST Number', _user.gstNumber!),
                      ] else ...[
                        _DetailRow(Icons.work_outline_rounded, 'Role', _user.role),
                        if (_user.specialization != null && _user.specialization!.isNotEmpty)
                          _DetailRow(Icons.star_outline_rounded, 'Specialization', _user.specialization!),
                      ],
                      for (final e in _rawExtra.entries)
                        if (e.value is! List && !_isTimestampKey(e.key))
                          _DetailRow(_extraFieldIcon(e.key), _prettifyKey(e.key), _formatExtraValue(e.key, e.value)),
                    ],
                  ),
                  for (final group in _chipGroups(accent)) ...[
                    const SizedBox(height: 14),
                    group,
                  ],
                  if (_isClient) ...[
                    const SizedBox(height: 14),
                    _ClientInvoicesCard(clientId: _user.id, accent: accent),
                  ],
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 250.ms),
      ),
    );
  }

  /// Every list-type value — connected platforms, or any array field the API
  /// sends (interests, tags, skills…) — gets its own pill/chip card, like the
  /// reference screenshot's "Interests" block.
  List<Widget> _chipGroups(Color accent) {
    final groups = <Widget>[];
    if (_user.platform.isNotEmpty) {
      groups.add(_PlatformsCard(platforms: _user.platform, accent: accent));
    }
    for (final e in _rawExtra.entries) {
      if (e.value is List) {
        final items = (e.value as List).map((x) => x.toString()).toList();
        if (items.isNotEmpty) {
          groups.add(_ChipsCard(title: _prettifyKey(e.key), items: items, accent: accent));
        }
      }
    }
    return groups;
  }

  String _prettifyKey(String key) {
    final spaced = key.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  IconData _extraFieldIcon(String key) {
    final k = key.toLowerCase();
    if (k.contains('status')) return Icons.verified_user_outlined;
    if (k.contains('id')) return Icons.tag_rounded;
    return Icons.info_outline_rounded;
  }

  bool _isTimestampKey(String key) {
    final k = key.toLowerCase();
    return k == 'createdat' || k == 'updatedat' || k.contains('created') || k.contains('updated');
  }

  /// True for values that carry no real information: null, empty/whitespace
  /// strings, empty lists/maps. (`false` booleans are kept — a real "No" is
  /// still meaningful data; only structurally-empty values are dropped.)
  static bool _isEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  /// Renders a raw JSON value for the "Additional Info" list — dates get
  /// formatted, lists get comma-joined, everything else falls back to string.
  static String _formatExtraValue(String key, dynamic value) {
    if (value is List) return value.map((e) => e.toString()).join(', ');
    if (value is String && (key.toLowerCase().contains('at') ) ) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        final local = parsed.toLocal();
        String two(int n) => n.toString().padLeft(2, '0');
        return '${two(local.day)}/${two(local.month)}/${local.year}';
      }
    }
    return value.toString();
  }
}

// ─── Header card: avatar, name, role + status badges ───────────────────────
// ─── Small helper: copy text + show a quiet confirmation toast ─────────────
void _copyToClipboard(BuildContext context, String label, String value) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$label copied', style: GoogleFonts.sora(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500)),
    backgroundColor: AppColors.surfaceLight,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 1400),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppColors.border)),
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    elevation: 0,
  ));
}

// ─── Full-bleed banner header: avatar, name, role/location ─────────────────
class _DetailHeaderBanner extends StatelessWidget {
  final AdminUserModel user;
  final Color accent;
  final bool isClient;
  const _DetailHeaderBanner({required this.user, required this.accent, required this.isClient});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = isClient
        ? [user.companyName, user.industry].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toList()
        : [user.role, user.specialization].where((s) => s != null && s.trim().isNotEmpty).cast<String>().toList();
    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' · ') : (isClient ? 'Client' : 'Team member');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.16),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: Center(
              child: Text(
                user.initial,
                style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.82)),
          ),
        ],
      ),
    );
  }
}

// ─── Overlapping card: quick-contact chips + record id (sits over the
// banner's bottom edge, mirroring the reference screenshot's "Profile
// strength" card position) ───────────────────────────────────────────────
class _QuickContactCard extends StatelessWidget {
  final AdminUserModel user;
  final Color accent;
  const _QuickContactCard({required this.user, required this.accent});

  @override
  Widget build(BuildContext context) {
    final hasEmail = user.email.isNotEmpty;
    final hasPhone = user.phone != null && user.phone!.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasEmail)
              SizedBox(width: double.infinity, child: _QuickContactChip(icon: Icons.mail_outline_rounded, value: user.email, accent: accent)),
            if (hasEmail && hasPhone) const SizedBox(height: 10),
            if (hasPhone)
              SizedBox(width: double.infinity, child: _QuickContactChip(icon: Icons.call_outlined, value: user.phone!, accent: accent)),
          ],
        ),
      ),
    );
  }
}

// ─── Plain paragraph card, e.g. "About me" / notes ──────────────────────────
class _AboutCard extends StatelessWidget {
  final String text;
  const _AboutCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Text(
              text,
              style: GoogleFonts.sora(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tappable quick-contact chip shown under the header ────────────────────
class _QuickContactChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color accent;
  const _QuickContactChip({required this.icon, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _copyToClipboard(context, 'Copied', value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Generic labeled section card: plain bold title, then label/value rows ─
class _DetailSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<_DetailRow> rows;
  const _DetailSection({required this.title, required this.accent, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.border.withOpacity(0.6)),
            for (int i = 0; i < rows.length; i++) ...[
              _DetailRowTile(row: rows[i], accent: accent),
              if (i != rows.length - 1) Container(height: 1, color: AppColors.border.withOpacity(0.35)),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ─── Chip/pill card for list-type data (interests, tags, connected platforms)
class _ChipsCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color accent;
  const _ChipsCard({required this.title, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: items.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text(t, style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w600, color: accent)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowTile extends StatelessWidget {
  final _DetailRow row;
  final Color accent;
  const _DetailRowTile({required this.row, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Tag/chip rows (e.g. interests, specializations, platforms saved as a
    // list) get their own layout: label on top, pills wrapped below.
    if (row.tags != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(row.icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  row.label,
                  style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (row.tags!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: row.tags!.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(0.25)),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                    ),
                  );
                }).toList(),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('—', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted)),
              ),
          ],
        ),
      );
    }

    // Standard row: icon + label on the left, value right-aligned on the
    // same line — mirrors the reference "Details" list layout.
    return InkWell(
      onTap: () => _copyToClipboard(context, row.label, row.value ?? ''),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(row.icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              row.label,
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(
                row.value ?? '',
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w700, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String? value;
  final List<String>? tags;
  const _DetailRow(this.icon, this.label, [this.value]) : tags = null;
  const _DetailRow.tags(this.icon, this.label, this.tags) : value = null;
}

// ─── Connected platforms chip row ───────────────────────────────────────────
class _PlatformsCard extends StatelessWidget {
  final List<String> platforms;
  final Color accent;
  const _PlatformsCard({required this.platforms, required this.accent});

  static const Map<String, _PlatMeta> _meta = {
    'instagram': _PlatMeta('Instagram', Icons.camera_alt_rounded, Color(0xFFE1306C)),
    'facebook': _PlatMeta('Facebook', Icons.facebook_rounded, Color(0xFF1877F2)),
    'twitter': _PlatMeta('Twitter / X', Icons.alternate_email_rounded, Color(0xFF1DA1F2)),
    'linkedin': _PlatMeta('LinkedIn', Icons.business_center_rounded, Color(0xFF0A66C2)),
    'youtube': _PlatMeta('YouTube', Icons.play_circle_fill_rounded, Color(0xFFFF0000)),
    'pinterest': _PlatMeta('Pinterest', Icons.push_pin_rounded, Color(0xFFE60023)),
    'threads': _PlatMeta('Threads', Icons.tag_rounded, Colors.black),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected Platforms', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: platforms.map((p) {
                final meta = _meta[p] ?? _PlatMeta(p, Icons.public_rounded, AppColors.textMuted);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta.icon, size: 15, color: meta.color),
                      const SizedBox(width: 6),
                      Text(meta.label, style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _PlatMeta(this.label, this.icon, this.color);
}

// ─────────────────────────────────────────
// CLIENT DETAIL PAGE → INVOICES SECTION
// GET /api/admin/invoices/client/:clientId — shown at the bottom of the
// client detail page, below "Details" / connected platforms etc.
// ─────────────────────────────────────────
class _ClientInvoicesCard extends StatefulWidget {
  final String clientId;
  final Color accent;
  const _ClientInvoicesCard({required this.clientId, required this.accent});

  @override
  State<_ClientInvoicesCard> createState() => _ClientInvoicesCardState();
}

class _ClientInvoicesCardState extends State<_ClientInvoicesCard> {
  final _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMsg;
  List<Map<String, dynamic>> _invoices = [];
  bool _isOpeningDownload = false;
  String? _downloadingInvoiceId;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final res = await _apiService.get('${AppConstants.adminInvoicesByClient}/${widget.clientId}');
      final invoices = parseInvoiceList(res);
      if (mounted) setState(() { _invoices = invoices; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = _cleanErr(e.toString()); _isLoading = false; });
    }
  }

  Future<void> _download(String url, String invoiceId) async {
    setState(() {
      _isOpeningDownload = true;
      _downloadingInvoiceId = invoiceId;
    });
    final err = await downloadInvoicePdf(url: url, invoiceId: invoiceId);
    if (mounted) {
      if (err != null) _showSuccessSnack(context, err);
      setState(() {
        _isOpeningDownload = false;
        _downloadingInvoiceId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return SizedBox(
      width: double.infinity,
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.receipt_long_rounded, size: 17, color: accent),
              const SizedBox(width: 8),
              Text('Invoices', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              if (!_isLoading)
                InkWell(
                  onTap: _fetchInvoices,
                  child: Icon(Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                ),
            ]),
            const SizedBox(height: 12),
            if (_isLoading)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ))
            else if (_errorMsg != null)
              _InvoiceInlineMessage(text: _errorMsg!, isError: true, onRetry: _fetchInvoices)
            else if (_invoices.isEmpty)
                _InvoiceInlineMessage(text: 'No invoices generated for this client yet.', isError: false)
              else
                Column(
                  children: [
                    for (int i = 0; i < _invoices.length; i++) ...[
                      if (i != 0) const SizedBox(height: 10),
                      _InvoiceListTile(
                        node: _invoices[i],
                        index: i,
                        accent: accent,
                        isDownloading: _isOpeningDownload &&
                            _downloadingInvoiceId == (invoiceField(_invoices[i], ['invoiceNumber', 'invoiceNo', 'number', '_id', 'id']) ?? '$i'),
                        isAnyDownloading: _isOpeningDownload,
                        onDownload: _download,
                      ),
                    ],
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceInlineMessage extends StatelessWidget {
  final String text;
  final bool isError;
  final VoidCallback? onRetry;
  const _InvoiceInlineMessage({required this.text, required this.isError, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isError ? AppColors.error : AppColors.textMuted).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isError ? AppColors.error : AppColors.textMuted).withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: GoogleFonts.sora(fontSize: 12.5, color: AppColors.textSecondary)),
        if (isError && onRetry != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onRetry,
            child: Text('Retry', style: GoogleFonts.sora(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.error)),
          ),
        ],
      ]),
    );
  }
}

class _InvoiceListTile extends StatelessWidget {
  final Map<String, dynamic> node;
  final int index;
  final Color accent;
  final bool isDownloading;
  final bool isAnyDownloading;
  final Future<void> Function(String url, String invoiceId) onDownload;

  const _InvoiceListTile({
    required this.node,
    required this.index,
    required this.accent,
    required this.isDownloading,
    required this.isAnyDownloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final invoiceId = invoiceField(node, ['invoiceNumber', 'invoiceNo', 'number', '_id', 'id']);
    final amount = invoiceField(node, ['totalAmount', 'amount', 'total']);
    final status = invoiceField(node, ['status']) ?? 'generated';
    final date = invoiceField(node, ['createdAt', 'date', 'issueDate']);
    final fileUrl = invoiceFileUrl(node);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (invoiceId != null) _InvoiceDetailLine('Invoice No.', invoiceId),
        if (amount != null) _InvoiceDetailLine('Amount', '\$₹{amount}'),
        _InvoiceDetailLine('Status', status),
        if (date != null) _InvoiceDetailLine('Date', date),
        if (fileUrl != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isAnyDownloading ? null : () => onDownload(fileUrl, invoiceId ?? '$index'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isDownloading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_rounded, color: accent, size: 16),
                  const SizedBox(width: 6),
                  Text('Download Invoice', style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}