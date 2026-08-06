import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/contact_form_service.dart';

import '../widgets/styled_input.dart';
import '../widgets/primary_button.dart';

class ContactForm extends StatefulWidget {
  final Function(String name, String email, String subject, String message)?
      onSubmit;

  const ContactForm({
    super.key,
    this.onSubmit,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final ContactFormService _contactFormService = ContactFormService();

  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _contactFormService.submitContactForm(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (widget.onSubmit != null) {
        widget.onSubmit!(
          _nameController.text,
          _emailController.text,
          _subjectController.text,
          _messageController.text,
        );
      }

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _isSuccess = false);
        }
      });
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit form: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border.all(
          color: AppTheme.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFormFields(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            if (_isSuccess) _buildSuccessMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send a Message',
          style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'I\'d love to hear from you. Send me a message and let\'s talk.',
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 500) {
            return Row(
              children: [
                Expanded(
                  child: StyledInput(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StyledInput(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                StyledInput(
                  controller: _nameController,
                  label: 'Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                StyledInput(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            );
          }
        }),
        const SizedBox(height: 20),
        StyledInput(
          controller: _subjectController,
          label: 'Subject',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a subject';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        StyledInput(
          controller: _messageController,
          label: 'Message',
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a message';
            }
            if (value.length < 10) {
              return 'Message must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return PrimaryButton(
      text: 'Send Message',
      isLoading: _isSubmitting,
      onPressed: _handleSubmit,
      width: double.infinity,
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurfaceElevated,
        border: Border.all(
          color: AppTheme.accentSecondary,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.accentSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Message sent successfully! I\'ll get back to you soon.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.ink),
            ),
          ),
        ],
      ),
    );
  }
}
