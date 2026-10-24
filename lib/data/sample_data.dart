import '../models/app_user.dart';
import '../models/cleaning_package.dart';
import '../models/condo.dart';

const cleaningPackages = <CleaningPackage>[
  CleaningPackage(
    id: 'standard',
    name: 'Standard Clean',
    tagline: 'Weekly upkeep for a tidy home',
    basePrice: 80,
    pricePerExtraBedroom: 15,
    durationHours: 2.5,
    includes: [
      'Dusting and wiping of all surfaces',
      'Vacuum and mop all floors',
      'Kitchen counters, sink and stovetop',
      'Bathrooms: toilet, shower, mirrors',
      'Trash taken out',
    ],
  ),
  CleaningPackage(
    id: 'deep',
    name: 'Deep Clean',
    tagline: 'Top to bottom, every corner',
    basePrice: 140,
    pricePerExtraBedroom: 25,
    durationHours: 4.5,
    includes: [
      'Everything in Standard Clean',
      'Inside oven, fridge and microwave',
      'Baseboards, door frames and switches',
      'Descale shower glass and taps',
      'Balcony sweep and window sills',
    ],
  ),
  CleaningPackage(
    id: 'move',
    name: 'Move In / Move Out',
    tagline: 'Empty unit, handover ready',
    basePrice: 220,
    pricePerExtraBedroom: 35,
    durationHours: 6,
    includes: [
      'Everything in Deep Clean',
      'Inside all cabinets, closets and drawers',
      'Wall spot cleaning',
      'Window tracks and blinds',
      'Checklist photos for your landlord',
    ],
  ),
];

const demoCleanerMaria = AppUser(
  id: 'cleaner-maria',
  name: 'Maria Santos',
  email: 'maria@sparknest.app',
  phone: '+1 415 555 0142',
  role: UserRole.cleaner,
);

const demoCleanerAna = AppUser(
  id: 'cleaner-ana',
  name: 'Ana Reyes',
  email: 'ana@sparknest.app',
  phone: '+1 415 555 0178',
  role: UserRole.cleaner,
);

/// Prefill values for the "Use sample details" buttons, so a demo can be
/// recorded without typing.
const sampleClientName = 'Daniel Carter';
const sampleClientEmail = 'daniel.carter@example.com';
const sampleClientPhone = '+1 415 555 0199';

const sampleCondo = Condo(
  buildingName: 'The Harbor Residences',
  address: '88 King St, San Francisco',
  tower: 'Tower B',
  unit: '1204',
  bedrooms: 2,
  bathrooms: 2,
  accessNotes: 'Concierge has a spare key. Visitor parking on P2.',
  hasPets: true,
);
