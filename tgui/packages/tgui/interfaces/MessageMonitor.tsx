import {
  Box,
  Button,
  Divider,
  NoticeBox,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface LogEntry {
  ref: string;
  send_dpt: string;
  rec_dpt: string;
  message: string;
  stamp: string;
  id_auth: string;
  priority: string;
}

interface MessageMonitorData {
  message: string;
  auth: boolean;
  hacking: boolean;
  emag: boolean;
  serverActive: boolean;
  hasServer: boolean;
  isAI: boolean;
  isMalfAI: boolean;
  screen: number;
  logs?: LogEntry[];
}

export const MessageMonitor = () => {
  const { act, data } = useBackend<MessageMonitorData>();
  const {
    message,
    auth,
    hacking,
    emag,
    serverActive,
    hasServer,
    isAI,
    isMalfAI,
    screen,
    logs = [],
  } = data;

  const renderMainMenu = () => {
    let optionCount = 1;

    return (
      <Stack vertical>
        <Stack.Item>
          <Button
            content={`${optionCount}. Link To A Server`}
            onClick={() => act('find')}
            mb={1}
          />
        </Stack.Item>

        {auth ? (
          !hasServer ? (
            <Stack.Item>
              <Box color="red">ERROR: Server not found!</Box>
            </Stack.Item>
          ) : (
            <>
              <Stack.Item>
                <Button
                  content={`${++optionCount}. View Request Console Logs`}
                  onClick={() => act('viewr')}
                  mb={1}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content={`${++optionCount}. Clear Request Console Logs`}
                  onClick={() => act('clearr')}
                  mb={1}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content={`${++optionCount}. Set Custom Key`}
                  onClick={() => act('pass')}
                  mb={1}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  content={`${++optionCount}. Send Admin Message`}
                  onClick={() => act('msg')}
                  mb={1}
                />
              </Stack.Item>
            </>
          )
        ) : (
          <>
            {[2, 3, 4, 5].map((num) => (
              <Stack.Item key={num}>
                <Box color="blue" mb={1}>
                  {num}. ---------------
                </Box>
              </Stack.Item>
            ))}
          </>
        )}

        {isMalfAI && (
          <Stack.Item>
            <Button
              content="*&#@#. Bruteforce Key"
              onClick={() => act('hack')}
              color="red"
              italic
              mb={1}
            />
          </Stack.Item>
        )}

        <Stack.Item>
          <Divider />
          {!auth ? (
            <NoticeBox>
              Please authenticate with the server in order to show additional
              options.
            </NoticeBox>
          ) : (
            <NoticeBox color="orange">
              Reg, #514 forbids sending messages to a Head of Staff containing
              Erotic Rendering Properties.
            </NoticeBox>
          )}
        </Stack.Item>
      </Stack>
    );
  };

  const renderHackingScreen = () => (
    <Box>
      {isAI ? (
        <Stack vertical>
          <Stack.Item>Brute-forcing for server key.</Stack.Item>
          <Stack.Item>
            It will take 20 seconds for every character that the password has.
          </Stack.Item>
          <Stack.Item>
            In the meantime, this console can reveal your true intentions if you
            let someone access it. Make sure no humans enter the room during
            that time.
          </Stack.Item>
        </Stack>
      ) : (
        <Box
          style={{
            fontFamily: 'monospace',
            fontSize: '10px',
            wordBreak: 'break-all',
          }}
        >
          <Stack vertical>
            <Stack.Item>
              01000010011100100111010101110100011001010010110
            </Stack.Item>
            <Stack.Item>
              10110011001101111011100100110001101101001011011100110011
            </Stack.Item>
            <Stack.Item>
              10010000001100110011011110111001000100000011100110110010
            </Stack.Item>
            <Stack.Item>
              10111001001110110011001010111001000100000011010110110010
            </Stack.Item>
            <Stack.Item>
              10111100100101110001000000100100101110100001000000111011
            </Stack.Item>
            <Stack.Item>
              10110100101101100011011000010000001110100011000010110101
            </Stack.Item>
            <Stack.Item>
              10110010100100000001100100011000000100000011100110110010
            </Stack.Item>
            <Stack.Item>
              10110001101101111011011100110010001110011001000000110011
            </Stack.Item>
            <Stack.Item>
              00110111101110010001000000110010101110110011001010111001
            </Stack.Item>
            <Stack.Item>
              00111100100100000011000110110100001100001011100100110000
            </Stack.Item>
            <Stack.Item>
              10110001101110100011001010111001000100000011101000110100
            </Stack.Item>
            <Stack.Item>
              00110000101110100001000000111010001101000011001010010000
            </Stack.Item>
            <Stack.Item>
              00111000001100001011100110111001101110111011011110111001
            </Stack.Item>
            <Stack.Item>
              00110010000100000011010000110000101110011001011100010000
            </Stack.Item>
            <Stack.Item>
              00100100101101110001000000111010001101000011001010010000
            </Stack.Item>
            <Stack.Item>
              00110110101100101011000010110111001110100011010010110110
            </Stack.Item>
            <Stack.Item>
              10110010100101100001000000111010001101000011010010111001
            </Stack.Item>
            <Stack.Item>
              10010000001100011011011110110111001110011011011110110110
            </Stack.Item>
            <Stack.Item>
              00110010100100000011000110110000101101110001000000111001
            </Stack.Item>
            <Stack.Item>
              00110010101110110011001010110000101101100001000000111100
            </Stack.Item>
            <Stack.Item>
              10110111101110101011100100010000001110100011100100111010
            </Stack.Item>
            <Stack.Item>
              10110010100100000011010010110111001110100011001010110111
            </Stack.Item>
            <Stack.Item>
              00111010001101001011011110110111001110011001000000110100
            </Stack.Item>
            <Stack.Item>
              10110011000100000011110010110111101110101001000000110110
            </Stack.Item>
            <Stack.Item>
              00110010101110100001000000111001101101111011011010110010
            </Stack.Item>
            <Stack.Item>
              10110111101101110011001010010000001100001011000110110001
            </Stack.Item>
            <Stack.Item>
              10110010101110011011100110010000001101001011101000010111
            </Stack.Item>
            <Stack.Item>
              00010000001001101011000010110101101100101001000000111001
            </Stack.Item>
            <Stack.Item>
              10111010101110010011001010010000001101110011011110010000
            </Stack.Item>
            <Stack.Item>
              00110100001110101011011010110000101101110011100110010000
            </Stack.Item>
            <Stack.Item>
              00110010101101110011101000110010101110010001000000111010
            </Stack.Item>
            <Stack.Item>
              00110100001100101001000000111001001101111011011110110110
            </Stack.Item>
            <Stack.Item>
              10010000001100100011101010111001001101001011011100110011
            </Stack.Item>
            <Stack.Item>
              10010000001110100011010000110000101110100001000000111010
            </Stack.Item>
            <Stack.Item>001101001011011010110010100101110</Stack.Item>
          </Stack>
        </Box>
      )}
    </Box>
  );

  const renderLogsScreen = () => (
    <Stack vertical>
      <Stack.Item>
        <Box textAlign="center" mb={2}>
          <Button content="Back" onClick={() => act('back')} mr={2} />
          <Button content="Refresh" onClick={() => act('refresh')} />
        </Box>
        <Divider />
      </Stack.Item>

      <Stack.Item>
        <Table>
          <Table.Row header>
            <Table.Cell width="5%">X</Table.Cell>
            <Table.Cell width="15%">Sending Dep.</Table.Cell>
            <Table.Cell width="15%">Receiving Dep.</Table.Cell>
            <Table.Cell width="40%">Message</Table.Cell>
            <Table.Cell width="15%">Stamp</Table.Cell>
            <Table.Cell width="15%">ID Auth.</Table.Cell>
            <Table.Cell width="15%">Priority</Table.Cell>
          </Table.Row>
          {logs.map((log, index) => (
            <Table.Row key={index}>
              <Table.Cell>
                <Button
                  content="X"
                  color="red"
                  onClick={() => act('deleter', { ref: log.ref })}
                />
              </Table.Cell>
              <Table.Cell>{log.send_dpt}</Table.Cell>
              <Table.Cell>{log.rec_dpt}</Table.Cell>
              <Table.Cell style={{ wordWrap: 'break-word' }}>
                {log.message}
              </Table.Cell>
              <Table.Cell>{log.stamp}</Table.Cell>
              <Table.Cell>{log.id_auth}</Table.Cell>
              <Table.Cell>{log.priority}</Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Stack.Item>
    </Stack>
  );

  return (
    <Window width={700} height={700}>
      <Window.Content scrollable>
        <Section title="Message Monitor Console">
          <Stack vertical>
            <Stack.Item>
              <Box textAlign="center" color="blue" fontSize="1.2em" mb={2}>
                {message}
              </Box>
            </Stack.Item>

            <Stack.Item>
              <Stack>
                <Stack.Item>
                  <Button
                    content={auth ? '[Authenticated]' : '[Unauthenticated]'}
                    color={auth ? 'green' : 'red'}
                    onClick={() => act('auth')}
                  />
                </Stack.Item>
                <Stack.Item ml={2}>
                  <Box inline mr={1}>
                    Server Power:
                  </Box>
                  {auth ? (
                    <Button
                      content={serverActive ? '[On]' : '[Off]'}
                      color={serverActive ? 'green' : 'red'}
                      onClick={() => act('active')}
                    />
                  ) : (
                    <Box
                      inline
                      color={serverActive ? 'green' : 'red'}
                      style={{ textDecoration: 'underline' }}
                    >
                      {serverActive ? '[On]' : '[Off]'}
                    </Box>
                  )}
                </Stack.Item>
              </Stack>
            </Stack.Item>

            <Stack.Item>
              <Divider />
              {screen === 0 && renderMainMenu()}
              {screen === 2 && renderHackingScreen()}
              {screen === 4 && renderLogsScreen()}
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
