import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/theme/fitness_theme.dart';

enum NewFoodAction { enterNutrition, combineFoods }

class NewFoodSheet extends StatelessWidget {
  const NewFoodSheet({super.key});

  Widget _option(BuildContext context, NewFoodAction action, String title,
          String detail) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
              color: FitnessTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: FitnessTheme.line, width: .7)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  key: ValueKey('new-food-${action.name}'),
                  onTap: () => Navigator.pop(context, action),
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              FitnessText(title,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              FitnessText(detail,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: FitnessTheme.muted)),
                            ])),
                        const SizedBox(width: 16),
                        const Icon(CupertinoIcons.chevron_right,
                            size: 13, color: FitnessTheme.muted),
                      ])))));

  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: SafeArea(
          top: false,
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .8),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          const Expanded(
                              child: FitnessText('Add your own',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -.5))),
                          CloseButton(onPressed: () => Navigator.pop(context)),
                        ]),
                        const SizedBox(height: 14),
                        _option(
                            context,
                            NewFoodAction.enterNutrition,
                            'Enter nutrition',
                            'Use values from a label or recipe.'),
                        _option(context, NewFoodAction.combineFoods,
                            'Combine foods', 'Choose foods to build a meal.'),
                      ])))));
}
