import 'package:m_o_b_demand_side/features/profile/domain/entities/faq_entry.dart';

/// Full mobSTAR FAQ list shown on `MobstarFaqPage`, in the same order as the
/// web "Frequently asked questions" section. Entries without an answer yet
/// render as a plain non-expandable row via `FaqAccordionTile` until their
/// content is added here.
const mobstarFaqEntries = <FaqEntry>[
  FaqEntry(
    'What is mobSTAR loyalty program?',
    "The mobSTAR Loyalty Program is Mad Over Buildings' exclusive loyalty "
        'program for material purchases. Earn mobSTAR points every time you '
        'buy directly through MOB and unlock more rewards & benefits as you '
        'level up. There are five levels: Bronze, Silver, Gold, Platinum, '
        'and Diamond.',
  ),
  FaqEntry(
    'How to register for mobSTAR loyalty program?',
    'Simply sign up using your registered mobile number and OTP to start '
        'enjoying mobSTAR benefits. Upgrade to mobPRO by adding your GSTIN '
        'anytime to unlock distributor-level pricing.',
  ),
  FaqEntry(
    'How do I earn points?',
    'You earn mobSTAR points as a percentage of your total purchase amount, '
        'depending on your membership level. The higher your level, the more '
        'points you earn with every purchase.',
  ),
  FaqEntry(
    'Why is Sign up necessary?',
    'Signing up allows us to securely link your purchases to your account '
        'so you can earn and track mobSTAR points. It also helps us '
        'personalise your experience, unlock exclusive rewards, and ensure '
        'that all your benefits are credited to the right account.',
  ),
  FaqEntry(
    'What if my mobSTAR balance is inaccurate?',
    'If you notice any discrepancy in your mobSTAR points balance, please '
        'contact our support team with your account details and purchase '
        'information. We will review your transactions and update your '
        'balance to reflect the correct points as quickly as possible.',
  ),
  FaqEntry(
    'When do mobSTAR points get credited?',
    'mobSTAR points get credited to your account 7 days after your order is '
        'marked delivered.',
  ),
  FaqEntry(
    'When do mobSTAR points expire?',
    'mobSTAR points are valid for one year from the date they are credited '
        'to your account. Any unused points will expire after this period, '
        'so be sure to redeem them in time to enjoy your rewards.',
  ),
  FaqEntry(
    'How does level upgrade happen?',
    'Your mobSTAR level upgrades automatically based on the total points '
        'you earn. You start at Bronze with 0 points, move to Silver at '
        '2,000 points, Gold at 12,000 points, Platinum at 30,000 points, and '
        'reach Diamond at 68,000 points. As you accumulate more points, you '
        'unlock higher levels and enjoy greater rewards.',
  ),
  FaqEntry(
    'Where can I find my mobSTAR points details?',
    'You can view your mobSTAR points and transaction history in the '
        'Account section of your MOB profile.',
  ),
  FaqEntry(
    'How to maintain your mobSTAR level status?',
    'Once you reach a level, you will remain at that level for a full year '
        'from the date you qualified. After the year ends, your level will '
        'be automatically evaluated based on your total points earned: if '
        "you meet or exceed your current level's requirement, you will stay "
        'at the same level; if your points are below the requirement, your '
        'level will be downgraded; and if you have earned enough points for '
        'a higher level, you will be upgraded.',
  ),
  FaqEntry(
    'Is there a membership fee?',
    'No, the mobSTAR Loyalty Program is completely free to join. All you '
        'need to do is sign up on MOB portal, and you can start earning '
        'points and enjoying rewards on the orders you place.',
  ),
  FaqEntry(
    'Why do mobSTAR points have expiration dates?',
    'mobSTAR points have expiration dates to encourage timely redemption '
        'and ensure a fair and active rewards system for all members. This '
        'helps you make the most of your points while allowing us to '
        'maintain and offer exciting rewards and benefits consistently.',
  ),
  FaqEntry(
    'Can I qualify for multiple years in a single year’s spend?',
    'No, mobSTAR level qualification and membership benefits are '
        'calculated on a yearly basis. While earning more points in a year '
        'can help you upgrade to a higher level, it does not allow you to '
        'extend or qualify for multiple years at once.',
  ),
  FaqEntry(
    'Can I redeem all my mobSTAR points at once?',
    'Yes, you can use all your points in a single transaction. If your '
        'points exceed the order amount, only the points needed for the '
        'order will be used.',
  ),
  FaqEntry(
    'How do I redeem my mobSTAR points?',
    'You can redeem your points during checkout when placing an order. '
        'Simply select the points option. If your points cover the total '
        'amount, no additional payment is needed. If not, you can pay the '
        'remaining balance using any other available payment method.',
  ),
  FaqEntry(
    'Are mobSTAR points transferable?',
    'No. MOBSTAR points collected in your account can only be used by you '
        'and cannot be transferred to another account. It remains locked '
        'with the same account (mobile) number used.',
  ),
];
