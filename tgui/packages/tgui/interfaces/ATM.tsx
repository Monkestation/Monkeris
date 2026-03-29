import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { Window } from '../layouts';

const SCREEN_MAIN = 0;
const SCREEN_SECURITY = 1;
const SCREEN_TRANSFER = 2;
const SCREEN_LOGS = 3;

type Transaction = {
  date: string;
  time: string;
  target_name: string;
  purpose: string;
  amount: number;
  source_terminal: string;
};

type ATMData = {
  machine_id: string;
  emagged: boolean;
  locked_down: boolean;
  has_card: boolean;
  card_name: string | null;
  card_account_number: number | null;
  authenticated: boolean;
  suspended: boolean;
  owner_name: string;
  balance: number;
  account_number: number;
  security_level: number;
  screen: number;
  transaction_log: Transaction[];
};

const LoginScreen = () => {
  const { act, data } = useBackend<ATMData>();
  const { card_account_number } = data;
  const [accountNum, setAccountNum] = useState(
    card_account_number ? String(card_account_number) : '',
  );
  const [pin, setPin] = useState('');

  useEffect(() => {
    setAccountNum(card_account_number ? String(card_account_number) : '');
  }, [card_account_number]);

  const submit = () => {
    if (!accountNum || !pin) return;
    act('attempt_auth', { account_num: accountNum, account_pin: pin });
    setPin('');
  };

  return (
    <Section title="Login">
      <LabeledList>
        <LabeledList.Item label="Account Number">
          <Input
            value={accountNum}
            placeholder="Account number"
            onChange={(val) => setAccountNum(val)}
            onEnter={submit}
          />
        </LabeledList.Item>
        <LabeledList.Item label="PIN">
          <Input
            value={pin}
            placeholder="PIN"
            onChange={(val) => setPin(val)}
            onEnter={submit}
          />
        </LabeledList.Item>
      </LabeledList>
      <Button
        mt={1}
        icon="sign-in-alt"
        disabled={!accountNum || !pin}
        onClick={submit}
      >
        Login
      </Button>
    </Section>
  );
};

const MainScreen = () => {
  const { act, data } = useBackend<ATMData>();
  const { owner_name, balance } = data;
  const [withdrawAmount, setWithdrawAmount] = useState(0);
  const [withdrawType, setWithdrawType] = useState<
    'withdrawal' | 'e_withdrawal'
  >('withdrawal');

  return (
    <>
      <Section title={`Welcome, ${owner_name}`}>
        <LabeledList>
          <LabeledList.Item label="Balance">
            <Box bold color="good">
              {balance} cr
            </Box>
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Withdraw">
        <Stack align="center" mb={1}>
          <Stack.Item>
            <Button
              selected={withdrawType === 'withdrawal'}
              onClick={() => setWithdrawType('withdrawal')}
            >
              Cash
            </Button>
            <Button
              selected={withdrawType === 'e_withdrawal'}
              onClick={() => setWithdrawType('e_withdrawal')}
            >
              Chargecard
            </Button>
          </Stack.Item>
        </Stack>
        <Stack align="center">
          <Stack.Item>
            <NumberInput
              value={withdrawAmount}
              minValue={0}
              maxValue={balance}
              step={1}
              onChange={(val: number) => setWithdrawAmount(val)}
            />
          </Stack.Item>
          <Stack.Item ml={1}>
            <Button
              icon="money-bill-wave"
              disabled={withdrawAmount <= 0}
              onClick={() =>
                act(withdrawType, { funds_amount: withdrawAmount })
              }
            >
              Withdraw
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
      <Section title="Options">
        <Stack vertical>
          <Stack.Item>
            <Button
              fluid
              icon="shield-alt"
              onClick={() =>
                act('view_screen', { view_screen: SCREEN_SECURITY })
              }
            >
              Change Account Security Level
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="exchange-alt"
              onClick={() =>
                act('view_screen', { view_screen: SCREEN_TRANSFER })
              }
            >
              Make Transfer
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="list"
              onClick={() => act('view_screen', { view_screen: SCREEN_LOGS })}
            >
              View Transaction Log
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button fluid icon="print" onClick={() => act('balance_statement')}>
              Print Balance Statement
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              fluid
              icon="sign-out-alt"
              color="red"
              onClick={() => act('logout')}
            >
              Logout
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

const SECURITY_LEVELS = [
  {
    level: 0,
    label: 'Level 0',
    desc: 'Card or account number with PIN required. Vending machines only require a card.',
  },
  {
    level: 1,
    label: 'Level 1',
    desc: 'Account number and PIN must be entered manually. Vending machines require card and PIN.',
  },
  {
    level: 2,
    label: 'Level 2',
    desc: 'Card, account number, and PIN all required.',
  },
];

const SecurityScreen = () => {
  const { act, data } = useBackend<ATMData>();
  const { security_level } = data;

  return (
    <Section
      title="Security Level"
      buttons={
        <Button
          icon="arrow-left"
          onClick={() => act('view_screen', { view_screen: SCREEN_MAIN })}
        >
          Back
        </Button>
      }
    >
      <Stack vertical>
        {SECURITY_LEVELS.map((l) => (
          <Stack.Item key={l.level}>
            <Button
              fluid
              disabled={security_level === l.level}
              color={security_level === l.level ? 'green' : 'default'}
              onClick={() =>
                act('change_security_level', { new_security_level: l.level })
              }
            >
              {l.label}
            </Button>
            <Box mt="2px" mb={1} ml="2px" fontSize="0.85em" color="label">
              {l.desc}
            </Box>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const TransferScreen = () => {
  const { act, data } = useBackend<ATMData>();
  const { balance } = data;
  const [targetAccount, setTargetAccount] = useState('');
  const [amount, setAmount] = useState(0);
  const [purpose, setPurpose] = useState('Funds transfer');

  return (
    <Section
      title="Transfer Funds"
      buttons={
        <Button
          icon="arrow-left"
          onClick={() => act('view_screen', { view_screen: SCREEN_MAIN })}
        >
          Back
        </Button>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Balance">{balance} cr</LabeledList.Item>
        <LabeledList.Item label="Target Account">
          <Input
            value={targetAccount}
            placeholder="Account number"
            onChange={(val) => setTargetAccount(val)}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Amount">
          <NumberInput
            value={amount}
            minValue={0}
            maxValue={balance}
            step={1}
            onChange={(val: number) => setAmount(val)}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Purpose">
          <Input value={purpose} onChange={(val) => setPurpose(val)} />
        </LabeledList.Item>
      </LabeledList>
      <Button
        mt={1}
        icon="exchange-alt"
        disabled={!targetAccount || amount <= 0}
        onClick={() =>
          act('transfer', {
            target_acc_number: targetAccount,
            funds_amount: amount,
            purpose: purpose,
          })
        }
      >
        Transfer Funds
      </Button>
    </Section>
  );
};

const LogsScreen = () => {
  const { act, data } = useBackend<ATMData>();
  const { transaction_log } = data;

  return (
    <Section
      title="Transaction Log"
      buttons={
        <>
          <Button icon="print" onClick={() => act('print_transaction')}>
            Print
          </Button>
          <Button
            icon="arrow-left"
            onClick={() => act('view_screen', { view_screen: SCREEN_MAIN })}
          >
            Back
          </Button>
        </>
      }
    >
      {!transaction_log || transaction_log.length === 0 ? (
        <Box color="label">No transactions recorded.</Box>
      ) : (
        <Table>
          <Table.Row header>
            <Table.Cell>Date</Table.Cell>
            <Table.Cell>Time</Table.Cell>
            <Table.Cell>Target</Table.Cell>
            <Table.Cell>Purpose</Table.Cell>
            <Table.Cell>Value</Table.Cell>
            <Table.Cell>Terminal</Table.Cell>
          </Table.Row>
          {transaction_log.map((t, i) => (
            <Table.Row key={i}>
              <Table.Cell>{t.date}</Table.Cell>
              <Table.Cell>{t.time}</Table.Cell>
              <Table.Cell>{t.target_name}</Table.Cell>
              <Table.Cell>{t.purpose}</Table.Cell>
              <Table.Cell color={t.amount >= 0 ? 'good' : 'bad'}>
                {t.amount} cr
              </Table.Cell>
              <Table.Cell>{t.source_terminal}</Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

export const ATM = () => {
  const { act, data } = useBackend<ATMData>();
  const {
    machine_id,
    emagged,
    locked_down,
    has_card,
    card_name,
    authenticated,
    suspended,
    screen,
  } = data;

  return (
    <Window width={520} height={450} title="Automatic Teller Machine">
      <Window.Content scrollable>
        <Box mb={1} fontSize="0.85em" opacity={0.6}>
          Terminal: {machine_id}. Report this code when contacting IT Support.
        </Box>
        {emagged ? (
          <NoticeBox danger>
            CARD READER ERROR - Unauthorized terminal access detected! This ATM
            has been locked. Please contact IT Support.
          </NoticeBox>
        ) : (
          <Stack vertical>
            <Stack.Item>
              <Section>
                <LabeledList>
                  <LabeledList.Item label="Card">
                    <Button
                      icon={has_card ? 'id-card' : 'eject'}
                      color={has_card ? 'good' : 'default'}
                      onClick={() => act('insert_card')}
                    >
                      {has_card ? card_name : '------'}
                    </Button>
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Stack.Item>
            <Stack.Item>
              {locked_down ? (
                <NoticeBox danger>
                  Maximum number of PIN attempts exceeded! Access to this ATM
                  has been temporarily disabled.
                </NoticeBox>
              ) : !authenticated ? (
                <LoginScreen />
              ) : suspended ? (
                <NoticeBox danger>
                  Access to this account has been suspended, and the funds
                  within frozen.
                </NoticeBox>
              ) : screen === SCREEN_SECURITY ? (
                <SecurityScreen />
              ) : screen === SCREEN_TRANSFER ? (
                <TransferScreen />
              ) : screen === SCREEN_LOGS ? (
                <LogsScreen />
              ) : (
                <MainScreen />
              )}
            </Stack.Item>
          </Stack>
        )}
      </Window.Content>
    </Window>
  );
};
