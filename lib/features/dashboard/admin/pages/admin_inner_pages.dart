import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _apiService = ApiService();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final res = await _apiService.post(AppConstants.createUser, body: {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text.trim(),
        'role': 'Client',
        'budget': _budgetCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
      });
      final msg = (res['msg'] ?? res['message'] ?? 'Client created successfully').toString();
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
    _companyCtrl.dispose(); _industryCtrl.dispose(); _budgetCtrl.dispose();
    _addressCtrl.dispose(); _passwordCtrl.dispose();
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
                  _SheetField(label: 'Phone Number', hint: 'e.g. +1 234 567 890', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Company Name *', hint: 'e.g. Fashion Brand Co.', icon: Icons.business_rounded, controller: _companyCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Industry', hint: 'e.g. Fashion & Lifestyle', icon: Icons.category_rounded, controller: _industryCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Monthly Budget (USD)', hint: 'e.g. 2500', icon: Icons.attach_money_rounded, controller: _budgetCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  // _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
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
  bool _isLoading = false;
  String? _errorMessage;
  final _apiService = ApiService();

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
          'role': 'Client',
          'budget': _budgetCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'phoneNumber': _phoneCtrl.text.trim(),
          'companyName': _companyCtrl.text.trim(),
          'industry': _industryCtrl.text.trim(),
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
                  _SheetField(label: 'Phone Number', hint: 'e.g. +1 234 567 890', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Company Name *', hint: 'e.g. Fashion Brand Co.', icon: Icons.business_rounded, controller: _companyCtrl, validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Industry', hint: 'e.g. Fashion & Lifestyle', icon: Icons.category_rounded, controller: _industryCtrl),
                  const SizedBox(height: 14),
                  _SheetField(label: 'Monthly Budget (USD)', hint: 'e.g. 2500', icon: Icons.attach_money_rounded, controller: _budgetCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  // _SheetField(label: 'Address / Location', hint: 'e.g. New York, USA', icon: Icons.location_on_rounded, controller: _addressCtrl),
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
                  _SheetField(label: 'Phone Number *', hint: 'e.g. +1 234 567 890', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null),
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
                  _SheetField(label: 'Phone Number', hint: 'e.g. +1 234 567 890', icon: Icons.phone_rounded, controller: _phoneCtrl, keyboardType: TextInputType.phone),
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

  const _SheetField({required this.label, required this.hint, required this.icon, required this.controller, this.keyboardType, this.validator, this.maxLines = 1});

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

// ─────────────────────────────────────────
// DATA MODELS  (local – for Projects page)
// ─────────────────────────────────────────
class _Project {
  final String name, platforms, status;
  final double progress;
  final Color color;
  const _Project(this.name, this.platforms, this.progress, this.status, this.color);
}
