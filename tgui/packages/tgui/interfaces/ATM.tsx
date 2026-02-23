import { useState } from 'react';
import {
  Box,
  Button,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface ATMData {
  machine_id: string;
  held_card: string | null;
  emagged: BooleanLike;
  locked_down: BooleanLike;
  authenticated: BooleanLike;
  screen: number;
  account?: {
    owner_name: string;
    money: number;
    security_level: number;
    suspended: BooleanLike;
  };
  transactions?: Array<{
    date: string;
    time: string;
    target_name: string;
    purpose: string;
    amount: number;
    source_terminal: string;
  }>;
  default_account_number?: string;
}

export const ATM = () => {
  const { act, data } = useBackend<ATMData>();
  const [accountNum, setAccountNum] = useState(
    data.default_account_number || '',
  );
  const [accountPin, setAccountPin] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [transferAmount, setTransferAmount] = useState('');
  const [transferTarget, setTransferTarget] = useState('');
  const [transferPurpose, setTransferPurpose] = useState('Funds transfer');
  const { machine_id, held_card, authenticated, screen, account, locked_down } =
    data;

  // Render different screens based on view_screen
  const renderScreen = () => {
    switch (screen) {
      case 1: // CHANGE_SECURITY_LEVEL
        return (
          <Section title="Security Level">
            <Box mb={2}>Select a new security level for this account:</Box>
            <LabeledList>
              <LabeledList.Item label="Level 0">
                <Button
                  content="Either account number and pin, or card and pin"
                  onClick={() =>
                    act('choice', {
                      choice: 'change_security_level',
                      new_security_level: 0,
                    })
                  }
                  disabled={account?.security_level === 0}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Level 1">
                <Button
                  content="Account number and pin required"
                  onClick={() =>
                    act('choice', {
                      choice: 'change_security_level',
                      new_security_level: 1,
                    })
                  }
                  disabled={account?.security_level === 1}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Level 2">
                <Button
                  content="Card and pin required"
                  onClick={() =>
                    act('choice', {
                      choice: 'change_security_level',
                      new_security_level: 2,
                    })
                  }
                  disabled={account?.security_level === 2}
                />
              </LabeledList.Item>
            </LabeledList>
            <Button
              mt={2}
              content="Back"
              onClick={() =>
                act('choice', {
                  choice: 'view_screen',
                  view_screen: 0,
                })
              }
            />
          </Section>
        );
      case 2: // TRANSFER_FUNDS
        return (
          <Section title="Transfer Funds">
            <LabeledList>
              <LabeledList.Item label="Target Account">
                <Input
                  value={transferTarget}
                  onChange={(e, value) => setTransferTarget(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Amount">
                <Input
                  value={transferAmount}
                  onChange={(e, value) => setTransferAmount(value)}
                />
              </LabeledList.Item>
              <LabeledList.Item label="Purpose">
                <Input
                  value={transferPurpose}
                  onChange={(e, value) => setTransferPurpose(value)}
                />
              </LabeledList.Item>
            </LabeledList>
            <Button
              mt={2}
              content="Transfer"
              onClick={() =>
                act('choice', {
                  choice: 'transfer',
                  target_acc_number: transferTarget,
                  funds_amount: transferAmount,
                  purpose: transferPurpose,
                })
              }
            />
            <Button
              mt={2}
              ml={1}
              content="Back"
              onClick={() =>
                act('choice', {
                  choice: 'view_screen',
                  view_screen: 0,
                })
              }
            />
          </Section>
        );
      case 3: // VIEW_TRANSACTION_LOGS
        return (
          <Section title="Transaction Log">
            <Table>
              <Table.Row header>
                <Table.Cell>Date</Table.Cell>
                <Table.Cell>Time</Table.Cell>
                <Table.Cell>Target</Table.Cell>
                <Table.Cell>Purpose</Table.Cell>
                <Table.Cell>Amount</Table.Cell>
                <Table.Cell>Terminal</Table.Cell>
              </Table.Row>
              {data.transactions?.map((T, i) => (
                <Table.Row key={i}>
                  <Table.Cell>{T.date}</Table.Cell>
                  <Table.Cell>{T.time}</Table.Cell>
                  <Table.Cell>{T.target_name}</Table.Cell>
                  <Table.Cell>{T.purpose}</Table.Cell>
                  <Table.Cell>{T.amount}</Table.Cell>
                  <Table.Cell>{T.source_terminal}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
            <Button
              mt={2}
              content="Print"
              onClick={() =>
                act('choice', {
                  choice: 'print_transaction',
                })
              }
            />
            <Button
              mt={2}
              ml={1}
              content="Back"
              onClick={() =>
                act('choice', {
                  choice: 'view_screen',
                  view_screen: 0,
                })
              }
            />
          </Section>
        );
      default:
        return (
          // Main screen with withdrawal controls
          <Section title="Actions">
            <Stack vertical>
              <Stack.Item>
                <Stack>
                  <Stack.Item>
                    <Input
                      width="100px"
                      placeholder="Amount"
                      value={withdrawAmount}
                      onChange={(e, value) => setWithdrawAmount(value)}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      mr={1}
                      icon="money-bill"
                      content="Withdraw Cash"
                      onClick={() =>
                        act('choice', {
                          choice: 'withdrawal',
                          funds_amount: withdrawAmount,
                        })
                      }
                    />
                    <Button
                      icon="credit-card"
                      content="E-Wallet"
                      onClick={() =>
                        act('choice', {
                          choice: 'e_withdrawal',
                          funds_amount: withdrawAmount,
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </Stack.Item>
              <Stack.Item mt={1}>
                <Box textAlign="center">
                  <Button
                    width="115px"
                    mr={1}
                    icon="exchange-alt"
                    content="Transfer"
                    onClick={() =>
                      act('choice', {
                        choice: 'view_screen',
                        view_screen: 2,
                      })
                    }
                  />
                  <Button
                    width="115px"
                    mr={1}
                    icon="list"
                    content="Log"
                    onClick={() =>
                      act('choice', {
                        choice: 'view_screen',
                        view_screen: 3,
                      })
                    }
                  />
                  <Button
                    width="115px"
                    mr={1}
                    icon="print"
                    content="Statement"
                    onClick={() =>
                      act('choice', {
                        choice: 'balance_statement',
                      })
                    }
                  />
                  <Button
                    width="115px"
                    icon="cog"
                    content="Security"
                    onClick={() =>
                      act('choice', {
                        choice: 'view_screen',
                        view_screen: 1,
                      })
                    }
                  />
                </Box>
                <Box mt={1} textAlign="center">
                  <Button
                    width="120px"
                    color="bad"
                    icon="sign-out-alt"
                    content="Logout"
                    onClick={() =>
                      act('choice', {
                        choice: 'logout',
                      })
                    }
                  />
                </Box>
              </Stack.Item>
            </Stack>
          </Section>
        );
    }
  };

  return (
    <Window width={770} height={550}>
      <Window.Content>
        <Stack vertical>
          <Stack.Item>
            <Section title="ATM Terminal">
              <LabeledList>
                <LabeledList.Item label="Terminal ID">
                  {machine_id}
                </LabeledList.Item>
                <LabeledList.Item label="Card">
                  {held_card ? (
                    <>
                      {held_card}
                      <Button
                        ml={1}
                        icon="eject"
                        content="Eject"
                        onClick={() => act('choice', { choice: 'insert_card' })}
                      />
                    </>
                  ) : (
                    <Button
                      icon="id-card"
                      content="Insert Card"
                      onClick={() => act('choice', { choice: 'insert_card' })}
                    />
                  )}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>

          {!!locked_down && (
            <Stack.Item>
              <NoticeBox>
                Maximum number of pin attempts exceeded! Access temporarily
                disabled.
              </NoticeBox>
            </Stack.Item>
          )}

          {!!authenticated && account && (
            <>
              <Stack.Item>
                <Section title="Account Information">
                  <LabeledList>
                    <LabeledList.Item label="Account Holder">
                      {account.owner_name}
                    </LabeledList.Item>
                    <LabeledList.Item label="Balance">
                      {account.money} Credits
                    </LabeledList.Item>
                    <LabeledList.Item label="Security Level">
                      Level {account.security_level}
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              </Stack.Item>

              <Stack.Item>{renderScreen()}</Stack.Item>
            </>
          )}

          {!authenticated && held_card && !locked_down && (
            <Stack.Item>
              <Section title="Authentication">
                <LabeledList>
                  <LabeledList.Item label="Account Number">
                    <Input
                      placeholder="Enter Account Number"
                      value={accountNum}
                      onChange={(e, value) => setAccountNum(value)}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="PIN">
                    <Input
                      placeholder="Enter PIN"
                      value={accountPin}
                      onChange={(e, value) => setAccountPin(value)}
                    />
                  </LabeledList.Item>
                </LabeledList>
                <Button
                  mt={2}
                  content="Login"
                  onClick={() =>
                    act('choice', {
                      choice: 'attempt_auth',
                      account_num: accountNum,
                      account_pin: accountPin,
                    })
                  }
                />
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
