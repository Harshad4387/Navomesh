export const formatDate = (date: Date): string => {
  return date.toISOString().split('T')[0];
};

export const getLastWeekDates = (): string[] => {
  const dates: string[] = [];
  const today = new Date();
  for (let i = 6; i >= 0; i--) {
    const date = new Date(today);
    date.setDate(today.getDate() - i);
    dates.push(formatDate(date));
  }
  return dates;
};

export const getDateLabel = (dateStr: string): string => {
  const date = new Date(dateStr);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  date.setHours(0, 0, 0, 0);

  const diffTime = today.getTime() - date.getTime();
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';

  return date.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
};

export const get7DaysAgoDate = (): string => {
  const date = new Date();
  date.setDate(date.getDate() - 7);
  return formatDate(date);
};

export const getTomorrowDate = (): string => {
  const date = new Date();
  date.setDate(date.getDate() + 1);
  return formatDate(date);
};
