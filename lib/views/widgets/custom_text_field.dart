import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final IconData icon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: theme.colorScheme.primary.withOpacity(0.5),
              size: 20,
            ),
            suffixIcon: isPassword
                ? Icon(
                    Icons.visibility_off_outlined,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 20,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
