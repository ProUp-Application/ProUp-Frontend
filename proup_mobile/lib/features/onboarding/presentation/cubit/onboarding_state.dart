class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
  });

  final int currentPage;

  bool get isLastPage => currentPage == 2;

  OnboardingState  copyWith({
    int? currentPage,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
    );
  }
}