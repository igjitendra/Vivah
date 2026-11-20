import { z } from 'zod';

export const CreatePersonSchema = z.object({
  name: z.string().min(1, 'नाम आवश्यक है').max(100),
  family_id: z.string().optional(),
  village: z.string().max(100).optional(),
  relationship: z.string().max(50).optional(),
  phone: z.string().max(15).optional(),
  notes: z.string().max(500).optional(),
});
export type CreatePersonInput = z.infer<typeof CreatePersonSchema>;

export const CreateFamilySchema = z.object({
  name: z.string().min(1, 'परिवार का नाम आवश्यक है').max(100),
  village: z.string().max(100).optional(),
});
export type CreateFamilyInput = z.infer<typeof CreateFamilySchema>;

export const CreateEventSchema = z.object({
  title: z.string().min(1, 'कार्यक्रम का नाम आवश्यक है').max(150),
  event_type: z.enum(['शादी', 'तिलक', 'मुंडन', 'बरात', 'सगाई', 'वर्षगांठ', 'गृह प्रवेश', 'अन्य']),
  event_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'तारीख YYYY-MM-DD format में होनी चाहिए'),
  person_id: z.string().optional(),
  notes: z.string().max(500).optional(),
});
export type CreateEventInput = z.infer<typeof CreateEventSchema>;

export const CreateEntryItemSchema = z.object({
  item_name: z.string().min(1, 'वस्तु का नाम आवश्यक है').max(100),
  quantity: z.number().positive('मात्रा 0 से अधिक होनी चाहिए'),
  unit: z.string().max(20).default('संख्या'),
  estimated_value_paise: z.number().int().nonnegative().optional(),
  condition: z.string().max(100).optional(),
});
export type CreateEntryItemInput = z.infer<typeof CreateEntryItemSchema>;

export const CreateEntrySchema = z.object({
  event_id: z.string().min(1, 'कार्यक्रम चुनें'),
  person_id: z.string().min(1, 'व्यक्ति चुनें'),
  direction: z.enum(['mila', 'diya']),
  cash_amount_paise: z.number().int().nonnegative('राशि 0 या उससे अधिक होनी चाहिए'),
  notes: z.string().max(500).optional(),
  items: z.array(CreateEntryItemSchema).default([]),
});
export type CreateEntryInput = z.infer<typeof CreateEntrySchema>;

export const CreateReminderSchema = z.object({
  person_id: z.string().min(1, 'व्यक्ति चुनें'),
  event_title: z.string().min(1, 'कार्यक्रम का नाम आवश्यक है').max(150),
  target_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  note: z.string().max(300).optional(),
});
export type CreateReminderInput = z.infer<typeof CreateReminderSchema>;
