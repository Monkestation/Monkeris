import {
  Box,
  Button,
  LabeledList,
  ProgressBar,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface GravityGeneratorData {
  breaker: boolean;
  on: boolean;
  charging_state: number;
  charge_count: number;
  status: string;
  statusText: string;
}

export const GravityGenerator = () => {
  const { act, data } = useBackend<GravityGeneratorData>();
  const { breaker, on, charging_state, charge_count, status, statusText } =
    data;

  const getStatusColor = () => {
    switch (status) {
      case 'warning':
        return 'red';
      case 'powered':
        return 'green';
      case 'unpowered':
        return 'grey';
      default:
        return 'default';
    }
  };

  return (
    <Window width={350} height={300}>
      <Window.Content>
        <Section title="Gravity Generator">
          <Stack vertical>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Gravity Generator Breaker">
                  <Stack>
                    <Stack.Item>
                      {breaker ? (
                        <>
                          <Box as="span" color="green" bold mr={1}>
                            ON
                          </Box>
                          <Button
                            content="OFF"
                            onClick={() => act('gentoggle')}
                          />
                        </>
                      ) : (
                        <>
                          <Button
                            content="ON"
                            onClick={() => act('gentoggle')}
                            mr={1}
                          />
                          <Box as="span" color="green" bold>
                            OFF
                          </Box>
                        </>
                      )}
                    </Stack.Item>
                  </Stack>
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>

            <Stack.Item>
              <Box bold mb={1}>
                Generator Status:
              </Box>
              <Box
                backgroundColor="rgba(0,0,0,0.1)"
                p={2}
                style={{ border: '1px solid #ccc' }}
              >
                {status === 'warning' && (
                  <Box color="red" bold mb={1}>
                    WARNING Radiation Detected.
                  </Box>
                )}
                <Box color={getStatusColor()}>{statusText}</Box>
                <Box mt={1}>Gravity Charge: {charge_count}%</Box>
                <ProgressBar
                  value={charge_count}
                  minValue={0}
                  maxValue={100}
                  color={
                    charge_count > 75
                      ? 'green'
                      : charge_count > 25
                        ? 'yellow'
                        : 'red'
                  }
                  mt={1}
                />
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
