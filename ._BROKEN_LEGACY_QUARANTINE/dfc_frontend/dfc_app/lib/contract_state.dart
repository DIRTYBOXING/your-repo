import 'contract_model.dart';

sealed class ContractState {}

class ContractInitial extends ContractState {}

class ContractLoading extends ContractState {}

class ContractLoaded extends ContractState {
  final List<ContractModel> contracts;
  final BudgetModel budget;
  ContractLoaded(this.contracts, this.budget);
}

class ContractError extends ContractState {
  final String message;
  ContractError(this.message);
}
