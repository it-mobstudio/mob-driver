/// A single FAQ question/answer pair. An empty [answer] means the content
/// hasn't been added yet — [FaqAccordionTile] renders those as a plain,
/// non-expandable row instead of a broken empty expansion.
class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}
