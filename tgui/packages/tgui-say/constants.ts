/** Window sizes in pixels */
export enum WindowSize {
  Small = 30,
  Medium = 50,
  Large = 70,
  Width = 231,
}

/** Line lengths for autoexpand */
export enum LineLength {
  Small = 20,
  Medium = 39,
  Large = 59,
}

/**
 * Radio prefixes.
 * Displays the name in the left button, tags a css class.
 */
export const RADIO_PREFIXES = {
  ':b ': 'io',
  ':c ': 'Cmd',
  ':e ': 'Engi',
  ':m ': 'Med',
  ':mi ': 'Med(I)',
  ':n ': 'Sci',
  ':o ': 'Spec',
  ':p ': 'AI',
  ':s ': 'Sec',
  ':si ': 'Sec(I)',
  ':t ': 'NT',
  ':u ': 'Supp',
  ':v ': 'Svc',
  ':x ': 'Pirate',
  ':y ': 'Merc',
} as const;
