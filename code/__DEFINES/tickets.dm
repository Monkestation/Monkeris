//Defines
//Deciseconds until ticket becomes stale if unanswered. Alerts admins.
#define TICKET_TIMEOUT 10 MINUTES // 10 minutes
//Decisecions before the user is allowed to open another ticket while their existing one is open.
#define TICKET_DUPLICATE_COOLDOWN 5 MINUTES // 5 minutes

//Status defines
#define TICKET_OPEN       1
#define TICKET_CLOSED     2
#define TICKET_RESOLVED   3
#define TICKET_STALE      4

#define TICKET_STAFF_MESSAGE_ADMIN_CHANNEL 1
#define TICKET_STAFF_MESSAGE_PREFIX 2
