# Life Tracker - User Guide

## Overview
Life Tracker is your personal productivity companion with **full user control**. Track habits across 6 life areas: Body, Mind, Money, Skill, Relationship, and Dharma.

---

## 🎯 Core Features

### 1. **Dashboard**
- **Today's Progress**: Circular indicator showing overall completion percentage
- **Weekly Chart**: Visual bar chart of last 7 days' performance
- **Earned Badges**: Recognition for achievements (Elite Day, Productive Day, Streaks)
- **6 Life Sections**: Expandable cards for each category

### 2. **Habit Management** (Full Control)

#### Adding Habits
- Tap **"Add New Habit"** button at the bottom of any section
- Enter habit title (e.g., "Morning Jog", "Reading")
- Works in ALL sections including Money

#### Editing Habits
- **Long-press** on any habit card
- Choose "Edit Title" to rename
- Choose "Delete" to remove (with confirmation)

#### Expanding/Collapsing
- **Tap** on habit to expand and see subtasks
- Tap again to collapse

### 3. **Subtask Management** (Full Control)

#### Adding Subtasks
- Expand a habit
- Tap **"Add Subtask"** button
- Choose type:
  - **Checkbox**: Simple done/not done (e.g., "Call Mom")
  - **Count**: Track numbers (e.g., "8 glasses of water")
- Set target value for count-based tasks

#### Editing Subtasks
- **Long-press** on any subtask
- Edit task name
- Edit target value (for count tasks)
- Or delete the subtask

#### Completing Subtasks
- **Checkbox tasks**: Tap the checkbox
- **Count tasks**: Use **+** and **-** buttons
  - Buttons turn grey when you reach limits
  - Haptic feedback on every tap

### 4. **Money Section**

#### Ledger System
- Track **Receivables** (money you'll receive)
- Track **Payables** (money you owe)
- See **Net Balance** at a glance

#### Adding Transactions
- Tap **"+ Add Entry"** button
- Enter person name, amount, and date
- Choose type: Receive or Payable
- Mark as paid with checkbox

#### Viewing All Transactions
- Tap **"View All Transactions"**
- See complete financial history
- Delete entries by swiping or tapping delete icon

#### Money Habits
- You can also add regular habits to Money section
- Example: "No Unnecessary Spend", "Budget Review"

### 5. **Gamification & Motivation**

#### Daily Badges
- **Elite Day**: >90% completion
- **Productive Day**: >70% completion

#### Streak Badges (per section)
- **🔥 Consistent**: 7+ day streak
- **🔥 Expert**: 21+ day streak  
- **🔥 Master**: 60+ day streak

#### Growth Milestones
- **Higher Growth!**: Triggers when you surpass yesterday's completion percentage.
- **ALL-TIME HIGH!**: Triggers when you break your personal best progress record.
- **Badge**: "All-Time High" appears in your achievements on record-breaking days.

#### Section Streaks
- Fire icon (🔥) appears on section cards
- Shows consecutive days of activity
- Color-coded: Bronze (7+), Silver (21+), Gold (60+)

### 6. **Settings**

#### Reset All Data
- Access via Settings icon in app bar
- **"Reset All Data"** button
- Clears all habits, transactions, and history
- Restores default examples
- **Use with caution!**

---

## 🎮 Interaction Guide

### Gestures
- **Tap**: Expand/collapse, check items, navigate
- **Long-press**: Edit or delete habits/subtasks
- **Swipe**: Delete transactions (in Money screen)

### Haptic Feedback
- Light vibration on taps (checkboxes, buttons)
- Medium vibration on long-press actions
- Confirms your actions instantly

### Visual Feedback
- Checkboxes turn checked ✓
- Completed tasks show strikethrough
- Progress circles fill up
- Disabled buttons turn grey
- Streak badges change color

---

## 📊 Progress Tracking

### How Completion Works
1. Each subtask has a target (1 for checkbox, custom for counts)
2. When all subtasks in a habit are complete, the habit is marked done
3. Daily completion = (completed habits / total habits) × 100%
4. Streaks count consecutive days with ANY activity in a section

### Weekly Chart Colors
- **Green**: 100% completion
- **Blue**: 50-99% completion  
- **Orange**: 1-49% completion
- **Grey**: 0% completion

---

## 💡 Tips & Best Practices

### Getting Started
1. **Delete default habits** you don't need (long-press → delete)
2. **Add your own habits** that match your goals
3. **Set realistic targets** for count-based tasks
4. **Start small** - 2-3 habits per section is plenty

### Customization Ideas

**Body Section:**
- Workout (Push-ups: 30, Squats: 40)
- Hydration (Water: 8 glasses)
- Sleep (7+ hours checkbox)

**Mind Section:**
- Reading (Pages: 20)
- Meditation (Minutes: 10)
- Learning (Course videos: 2)

**Money Section:**
- No impulse buy (checkbox)
- Budget review (checkbox)
- Track receivables/payables in ledger

**Skill Section:**
- Practice coding (Minutes: 60)
- Language learning (Lessons: 3)
- Musical practice (Minutes: 30)

**Relationship Section:**
- Call family (checkbox)
- Quality time with partner (checkbox)
- Message friends (Count: 3)

**Dharma Section:**
- Gratitude journal (checkbox)
- Help someone (checkbox)
- Reflection time (Minutes: 15)

### Maintaining Streaks
- Complete at least ONE subtask in a section daily
- Streaks continue if you complete tasks yesterday OR today
- Missing 2+ days breaks the streak
- Focus on consistency over perfection

---

## 🔧 Troubleshooting

### Data Not Saving?
- Changes save automatically when you interact
- If issues persist, restart the app

### Want to Start Fresh?
- Settings → Reset All Data
- This clears everything and restores defaults

### Accidentally Deleted Something?
- No undo feature currently
- Be careful with delete actions
- Consider resetting data if needed

---

## 🎨 Design Philosophy

**Minimal & Clean**
- Soft pastel colors for calm focus
- No clutter or distractions
- Fast, one-tap interactions

**User Control**
- Nothing is fixed or locked
- Customize everything to your needs
- Your data, your way

**Low Friction**
- Quick to open and update
- No login or sync required
- Local storage for privacy

---

## 📱 Technical Details

- **Platform**: Flutter (Windows, Android, iOS, Web)
- **Storage**: Hive (local database)
- **Offline**: Works completely offline
- **Privacy**: All data stays on your device

---

## 🚀 Future Ideas (Not Implemented)

- Export data to CSV/JSON
- Dark mode toggle
- Custom section colors
- Habit templates
- Reminder notifications
- Data backup/restore

---

**Version**: 1.0.0  
**Last Updated**: February 2026

---

## Quick Reference Card

| Action | How To |
|--------|--------|
| Add Habit | Tap "Add New Habit" in section |
| Edit Habit | Long-press habit → Edit Title |
| Delete Habit | Long-press habit → Delete |
| Add Subtask | Expand habit → "Add Subtask" |
| Edit Subtask | Long-press subtask |
| Delete Subtask | Long-press subtask → Delete |
| Complete Checkbox | Tap checkbox |
| Increment Count | Tap + button |
| Decrement Count | Tap - button |
| Add Money Entry | Money section → "+ Add Entry" |
| View All Money | Money section → "View All" |
| Reset Everything | Settings → Reset All Data |

---

**Enjoy tracking your life journey! 🌟**
