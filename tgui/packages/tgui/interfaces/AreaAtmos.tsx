import { Box, Button, Section, Stack, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface ScrubberData {
  name: string;
  pressure: number;
  flow_rate: number;
  power_draw: number;
  ref: string;
}

interface AreaAtmosData {
  status: string;
  zone: string;
  scrubbers: ScrubberData[];
}

export const AreaAtmos = () => {
  const { act, data } = useBackend<AreaAtmosData>();
  const { status, zone, scrubbers } = data;

  return (
    <Window width={400} height={400}>
      <Window.Content>
        <Section title="Area Air Control">
          <Stack vertical>
            {status && (
              <Stack.Item>
                <Box color="red" mb={2}>
                  {status}
                </Box>
              </Stack.Item>
            )}

            <Stack.Item>
              <Button content="Scan" onClick={() => act('scan')} mb={2} />
            </Stack.Item>

            <Stack.Item>
              <Table>
                {scrubbers.map((scrubber, index) => (
                  <Table.Row key={index}>
                    <Table.Cell>
                      <Stack vertical>
                        <Stack.Item>
                          <Box bold>{scrubber.name}</Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Box>Pressure: {scrubber.pressure} kPa</Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Box>Flow Rate: {scrubber.flow_rate} L/s</Box>
                        </Stack.Item>
                      </Stack>
                    </Table.Cell>
                    <Table.Cell width="150px">
                      <Stack vertical>
                        <Stack.Item>
                          <Button
                            content="Turn On"
                            color="green"
                            onClick={() =>
                              act('toggle_scrubber', {
                                ref: scrubber.ref,
                                state: '1',
                              })
                            }
                            mr={1}
                          />
                          <Button
                            content="Turn Off"
                            color="red"
                            onClick={() =>
                              act('toggle_scrubber', {
                                ref: scrubber.ref,
                                state: '0',
                              })
                            }
                          />
                        </Stack.Item>
                        <Stack.Item>
                          <Box>Load: {scrubber.power_draw} W</Box>
                        </Stack.Item>
                      </Stack>
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Stack.Item>

            <Stack.Item>
              <Box italic textAlign="center" mt={2}>
                {zone}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
