Suit :: enum {
    CLUB    :: 1;
    HEART   :: 2;
    SPADE   :: 4;
    DIAMOND :: 8;
}

// Done like this to detect straights easier
// I feel smart doing this :)
Rank :: enum u16 {
    ACE     :: 0b0010000000000001;
    TWO     :: 0b0000000000000010;
    THREE   :: 0b0000000000000100;
    FOUR    :: 0b0000000000001000;
    FIVE    :: 0b0000000000010000;
    SIX     :: 0b0000000000100000;
    SEVEN   :: 0b0000000001000000;
    EIGHT   :: 0b0000000010000000;
    NINE    :: 0b0000000100000000;
    TEN     :: 0b0000001000000000;
    JACK    :: 0b0000010000000000;
    QUEEN   :: 0b0000100000000000;
    KING    :: 0b0001000000000000;
    ZERO    :: 0b0000000000000000; // Definetly something fancy to do here
}

Hand :: enum int {
    HIGH_CARD;
    TWO_KIND;
    THREE_KIND;
    FOUR_KIND;
    FIVE_KIND;
    TWO_PAIR;
    FULL_HOUSE;
    STRAIGHT;
    FLUSH;
    FLUSH_HOUSE;
    STRAIGHT_FLUSH;
    FLUSH_FIVE;
}

HAND_NAMES : [12]string : .[
    "High Card",
    "Two of a Kind",
    "Three of a Kind",
    "Four of a Kind",
    "Five of a Kind",
    "Two Pair",
    "Full House",
    "Straight",
    "Flush",
    "Flush House",
    "Straight Flush",
    "Flush Five"
];

HAND_SCORES : [12]float : .[
    // XX = done
    1.0,  // High card XX
    1.5,  // 2 kind
    2.0,  // 3 kind
    4.0,  // 4 kind
    6.0,  // 5 kind
    1.75, // 2 pair 
    5.0,  // full house
    4.0,  // straight XX
    2.0,  // flush XX
    
    // shit gets crazy if you score one of these. Global score modifiers for x turns?
    10.0, // flush house
    12.0, // straight flush XX
    15.0, // flush five
];

RANK_SCORES : [14]float : .[
    0,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    10,
    10,
    10,
    11,
];

Card :: struct {
    rank : Rank = .ACE;
    suit : Suit = .SPADE;
}

RANKS : [13]Rank : .[
    .ACE, .TWO, .THREE, .FOUR, .FIVE, .SIX, .SEVEN, .EIGHT, .NINE, .TEN,
    .JACK, .QUEEN, .KING,
];

SUITS : [4]Suit : .[.HEART, .SPADE, .DIAMOND, .CLUB];

STANDARD_DECK : [52]Card : #run generate_standard_deck();
STRAIGHTS     : [10]u16  : .[
    0b0011111000000001,
    0b0001111100000000,
    0b0000111110000000,
    0b0000011111000000,
    0b0000001111100000,
    0b0000000111110000,
    0b0000000011111000,
    0b0000000001111100,
    0b0000000000111110,
    0b0010000000011111,
];

generate_standard_deck :: () -> [52]Card #compile_time {
    deck : [52]Card;

    suit_num : int = 0;
    rank_num : int = 0;
    index    : int = 0;
    for suit : SUITS {

        suit_num = it_index;
        for rank : RANKS {
            rank_num = it_index;

            index = (suit_num * 13) + rank_num;

            deck[index] = .{rank, suit};
        };
    };

    return deck;
};

draw_random_card :: (deck : *[..]Card) -> Card, bool {
    index : int = xx random_get_within_range(0.0, (deck.count-1).(float));
    
    if !(index < deck.*.count-1) then return .{}, false;
    
    card : Card = deck.*[index];

    array_unordered_remove_by_index(deck, index);
    return card, true;
}

calculate_card_score :: (card : Card) -> float {
    return RANK_SCORES[bit_scan_reverse(card.rank)-1];
}

calculate_hand_bonus :: (cards : [..]Card) -> float, Hand {
    is_flush    : bool;
    is_straight : bool;
    
    straight_bits : u16;
    flush_bits    : u16;
    
    current_hand  : Hand = .HIGH_CARD;
    
    for card : cards {
        straight_bits |= card.rank.(u16);
        flush_bits    |= card.suit.(u16);
    };
    
    is_straight = array_find(STRAIGHTS, straight_bits);     
    if is_straight then current_hand = .STRAIGHT;
    
    //print("%\n", formatInt(flush_bits, 2, 16));
    
    is_flush = ((flush_bits == 1) || (flush_bits == 2) || (flush_bits == 4) || (flush_bits == 8)) && cards.count == 5;
    if is_flush {
        current_hand = (ifx current_hand == .STRAIGHT then .STRAIGHT_FLUSH else .FLUSH);
    }

    return get_hand_score(current_hand), current_hand;
}

get_hand_name :: (hand : Hand) -> string {
    return HAND_NAMES[hand.(int)];
}

get_hand_score :: (hand : Hand) -> float {
    return HAND_SCORES[hand.(int)];
}