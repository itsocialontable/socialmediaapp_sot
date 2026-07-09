// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:provider/provider.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/providers/auth_provider.dart';
// import '../../../shared/widgets/common_widgets.dart';
//
// class AdminRegisterScreen extends StatefulWidget {
//   const AdminRegisterScreen({super.key});
//
//   @override
//   State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
// }
//
// class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmController = TextEditingController();
//   bool _isLoading = false;
//   bool _agreedToTerms = false;
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (!_agreedToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please agree to Terms & Conditions')),
//       );
//       return;
//     }
//     setState(() => _isLoading = true);
//     final auth = context.read<AuthProvider>();
//     final success = await auth.registerAdmin(
//         _nameController.text, _emailController.text, _passwordController.text);
//     if (mounted) {
//       setState(() => _isLoading = false);
//       if (success) context.go('/dashboard/admin');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CommonScaffold(
//       appBar: CommonAppBar(
//
//         title: 'Admin Register',
//         gradientStart: AppColors.adminColor,
//         gradientEnd: AppColors.primaryLight,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 const SizedBox(height: 24),
//
//                 Container(
//                   width: 72,
//                   height: 72,
//                   decoration: BoxDecoration(
//                     gradient: AppColors.adminGradient,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                           color: AppColors.adminColor.withOpacity(0.3),
//                           blurRadius: 20,
//                           offset: const Offset(0, 8)),
//                     ],
//                   ),
//                   child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
//                 ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
//
//                 const SizedBox(height: 16),
//
//                 Text('Admin Register',
//                     style: GoogleFonts.sora(
//                         fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
//                     .animate(delay: 100.ms).fadeIn(),
//
//                 Text('Create your admin account',
//                     style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary))
//                     .animate(delay: 150.ms).fadeIn(),
//
//                 const SizedBox(height: 32),
//
//                 CommonTextField(
//                   label: 'Full Name',
//                   hint: 'John Doe',
//                   prefixIcon: Icons.person_outline_rounded,
//                   controller: _nameController,
//                   accentColor: AppColors.adminColor,
//                   validator: (v) => (v?.isEmpty ?? true) ? 'Enter name' : null,
//                 ).animate(delay: 200.ms).fadeIn(),
//
//                 const SizedBox(height: 18),
//
//                 CommonTextField(
//                   label: 'Email Address',
//                   hint: 'admin@gmail.com',
//                   prefixIcon: Icons.mail_outline_rounded,
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   accentColor: AppColors.adminColor,
//                   validator: (v) => (v?.isEmpty ?? true) ? 'Enter email' : null,
//                 ).animate(delay: 250.ms).fadeIn(),
//
//                 const SizedBox(height: 18),
//
//                 CommonTextField(
//                   label: 'Password',
//                   hint: '••••••••••',
//                   prefixIcon: Icons.lock_outline_rounded,
//                   isPassword: true,
//                   controller: _passwordController,
//                   accentColor: AppColors.adminColor,
//                   validator: (v) => (v?.isEmpty ?? true) ? 'Enter password' : null,
//                 ).animate(delay: 300.ms).fadeIn(),
//
//                 const SizedBox(height: 18),
//
//                 CommonTextField(
//                   label: 'Confirm Password',
//                   hint: '••••••••••',
//                   prefixIcon: Icons.lock_outline_rounded,
//                   isPassword: true,
//                   controller: _confirmController,
//                   accentColor: AppColors.adminColor,
//                   validator: (v) {
//                     if (v?.isEmpty ?? true) return 'Confirm password';
//                     if (v != _passwordController.text) return 'Passwords do not match';
//                     return null;
//                   },
//                 ).animate(delay: 350.ms).fadeIn(),
//
//                 const SizedBox(height: 20),
//
//                 GestureDetector(
//                   onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
//                   child: Row(
//                     children: [
//                       AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         width: 20,
//                         height: 20,
//                         decoration: BoxDecoration(
//                           color: _agreedToTerms ? AppColors.adminColor : Colors.transparent,
//                           borderRadius: BorderRadius.circular(5),
//                           border: Border.all(
//                               color: _agreedToTerms ? AppColors.adminColor : AppColors.border),
//                         ),
//                         child: _agreedToTerms
//                             ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
//                             : null,
//                       ),
//                       const SizedBox(width: 10),
//                       Text.rich(
//                         TextSpan(
//                           text: 'I agree to the ',
//                           style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
//                           children: [
//                             TextSpan(
//                               text: 'Terms & Conditions',
//                               style: GoogleFonts.sora(
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                   color: AppColors.adminColor),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ).animate(delay: 400.ms).fadeIn(),
//
//                 const SizedBox(height: 28),
//
//                 CommonButton(
//                   label: 'Register',
//                   gradient: AppColors.adminGradient,
//                   isLoading: _isLoading,
//                   onTap: _register,
//                 ).animate(delay: 450.ms).fadeIn(),
//
//                 const SizedBox(height: 20),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text('Already have an account? ',
//                         style:
//                             GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
//                     GestureDetector(
//                       onTap: () => context.go('/auth/admin/login'),
//                       child: Text('Login',
//                           style: GoogleFonts.sora(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.adminColor)),
//                     ),
//                   ],
//                 ).animate(delay: 500.ms).fadeIn(),
//
//                 const SizedBox(height: 32),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
