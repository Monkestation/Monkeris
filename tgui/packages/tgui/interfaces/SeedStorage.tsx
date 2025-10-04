import { Box, Button, NoticeBox, Section, Table } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

interface SeedData {
  id: number;
  name: string;
  variety: number;
  amount: number;
  endurance?: number;
  yield?: number;
  maturation?: number;
  production?: number;
  potency?: number;
  harvest?: string;
  ideal_heat?: number;
  ideal_light?: number;
  nutrients?: string;
  water?: string;
  notes: string;
}

interface SeedStorageData {
  scanner: string[];
  seeds: SeedData[];
}

export const SeedStorage = () => {
  const { act, data } = useBackend<SeedStorageData>();
  const { scanner, seeds } = data;

  const hasStats = scanner.includes('stats');
  const hasTemperature = scanner.includes('temperature');
  const hasLight = scanner.includes('light');
  const hasSoil = scanner.includes('soil');

  return (
    <Window width={1000} height={600}>
      <Window.Content scrollable>
        <Section title="Seed Storage Contents">
          {seeds.length === 0 ? (
            <NoticeBox color="red">No seeds</NoticeBox>
          ) : (
            <Table>
              <Table.Row header>
                <Table.Cell>Name</Table.Cell>
                <Table.Cell>Variety</Table.Cell>
                {hasStats && (
                  <>
                    <Table.Cell>E</Table.Cell>
                    <Table.Cell>Y</Table.Cell>
                    <Table.Cell>M</Table.Cell>
                    <Table.Cell>Pr</Table.Cell>
                    <Table.Cell>Pt</Table.Cell>
                    <Table.Cell>Harvest</Table.Cell>
                  </>
                )}
                {hasTemperature && <Table.Cell>Temp</Table.Cell>}
                {hasLight && <Table.Cell>Light</Table.Cell>}
                {hasSoil && (
                  <>
                    <Table.Cell>Nutri</Table.Cell>
                    <Table.Cell>Water</Table.Cell>
                  </>
                )}
                <Table.Cell>Notes</Table.Cell>
                <Table.Cell>Amount</Table.Cell>
                <Table.Cell>Actions</Table.Cell>
              </Table.Row>
              {seeds.map((seed) => (
                <Table.Row key={seed.id}>
                  <Table.Cell>{seed.name}</Table.Cell>
                  <Table.Cell>#{seed.variety}</Table.Cell>
                  {hasStats && (
                    <>
                      <Table.Cell>{seed.endurance}</Table.Cell>
                      <Table.Cell>{seed.yield}</Table.Cell>
                      <Table.Cell>{seed.maturation}</Table.Cell>
                      <Table.Cell>{seed.production}</Table.Cell>
                      <Table.Cell>{seed.potency}</Table.Cell>
                      <Table.Cell>{seed.harvest}</Table.Cell>
                    </>
                  )}
                  {hasTemperature && (
                    <Table.Cell>{seed.ideal_heat} K</Table.Cell>
                  )}
                  {hasLight && <Table.Cell>{seed.ideal_light} L</Table.Cell>}
                  {hasSoil && (
                    <>
                      <Table.Cell>{seed.nutrients}</Table.Cell>
                      <Table.Cell>{seed.water}</Table.Cell>
                    </>
                  )}
                  <Table.Cell>
                    <Box fontSize="0.9em">
                      {seed.notes.split(' ').map((note, index) => {
                        const isWarning =
                          note.includes('!') ||
                          note.includes('CARN') ||
                          note.includes('VINE');
                        return (
                          <Box
                            key={index}
                            as="span"
                            color={isWarning ? 'red' : 'default'}
                            mr={0.5}
                          >
                            {note}
                          </Box>
                        );
                      })}
                    </Box>
                  </Table.Cell>
                  <Table.Cell>{seed.amount}</Table.Cell>
                  <Table.Cell>
                    <Button
                      content="Vend"
                      onClick={() =>
                        act('vend', {
                          id: seed.id,
                        })
                      }
                    />
                    <Button
                      ml={1}
                      content="Purge"
                      color="red"
                      onClick={() =>
                        act('purge', {
                          id: seed.id,
                        })
                      }
                    />
                  </Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
