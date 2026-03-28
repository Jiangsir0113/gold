import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existing;
  final void Function(Transaction) onSubmit;

  const TransactionForm({super.key, this.existing, required this.onSubmit});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late DateTime _date;
  final _gramsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'buy';
    _date = e?.date ?? DateTime.now();
    _gramsCtrl.text = e != null ? e.grams.toString() : '';
    _priceCtrl.text = e != null ? e.pricePerG.toString() : '';
    _feeCtrl.text = e != null ? e.fee.toString() : '0';
    _noteCtrl.text = e?.note ?? '';
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _priceCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final tx = Transaction(
      id: widget.existing?.id ?? 0,
      date: _date,
      type: _type,
      grams: double.parse(_gramsCtrl.text),
      pricePerG: double.parse(_priceCtrl.text),
      fee: double.tryParse(_feeCtrl.text) ?? 0,
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    );
    widget.onSubmit(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? '添加交易' : '编辑交易',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'buy', label: Text('买入')),
                ButtonSegment(value: 'sell', label: Text('卖出')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('日期：${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              contentPadding: EdgeInsets.zero,
            ),
            TextFormField(
              controller: _gramsCtrl,
              decoration: const InputDecoration(labelText: '克数', suffixText: '克'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : '请输入有效克数',
            ),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: '成交价', suffixText: '元/克'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : '请输入有效价格',
            ),
            TextFormField(
              controller: _feeCtrl,
              decoration: const InputDecoration(labelText: '手续费', suffixText: '元'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: '备注（可选）'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _submit, child: const Text('保存')),
            ),
          ],
        ),
      ),
    );
  }
}
