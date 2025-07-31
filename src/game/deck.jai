Suit :: enum {
    CLUB    :: 0;
    HEART   :: 1;
    SPADE   :: 2;
    DIAMOND :: 3;
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

draw_random_card :: (deck : [..]Card) -> Card {
    index : int = xx random_get_within_range(0.0, (deck.count-1).(float));
    card : Card = deck[index];

    array_unordered_remove_by_index(*deck, index);
    return card;
}