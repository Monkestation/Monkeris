import { Box, Button, Table } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { sendAct } from '../backend';

export interface ComputerInterface {
  PC_batteryicon: string;
  PC_batterypercent: string;
  PC_showbatteryicon: BooleanLike;
  PC_light_name: string;
  PC_light_on: BooleanLike;
  PC_apclinkicon: string;
  PC_ntneticon: string;
  has_gps: BooleanLike;
  gps_icon: string;
  gps_data: string;
  PC_programheaders: Programheader[];
  PC_stationtime: string;
  PC_hasheader: BooleanLike;
  PC_showexitprogram: BooleanLike;
  mapZLevels: number[];
  mapZLevel: number;
}

type Programheader = {
  icon: string;
};

export const ProgramShell = (props: ComputerInterface) => {
  const {
    PC_batteryicon,
    PC_batterypercent,
    PC_showbatteryicon,
    PC_light_name,
    PC_light_on,
    PC_apclinkicon,
    PC_ntneticon,
    has_gps,
    gps_icon,
    gps_data,
    PC_programheaders,
    PC_stationtime,
    PC_hasheader,
    PC_showexitprogram,
    mapZLevels,
    mapZLevel,
  } = props;
  const act = sendAct;
  return (
    <>
      <Box id="uiHeaderContent">
        {
          // Add a template with the key "headerContent" to have it rendered here -->
        }
        {PC_hasheader}
        <Box className="uiModularHeader">
          <Box left>
            <Box p="0px">
              <Table>
                <Table.Row>
                  {PC_batteryicon && PC_showbatteryicon && (
                    <Table.Cell>
                      <img src={PC_batteryicon} />
                    </Table.Cell>
                  )}
                  {PC_batterypercent && PC_showbatteryicon && (
                    <Table.Cell>
                      <Box bold>{PC_batterypercent}</Box>
                    </Table.Cell>
                  )}
                  {PC_ntneticon && (
                    <Table.Cell>
                      <img src={PC_ntneticon} />
                    </Table.Cell>
                  )}
                  {PC_apclinkicon && (
                    <Table.Cell>
                      <img src={PC_apclinkicon} />
                    </Table.Cell>
                  )}
                  {PC_stationtime && (
                    <Table.Cell>
                      <Box bold>{PC_stationtime}</Box>
                    </Table.Cell>
                  )}
                  {PC_programheaders &&
                    PC_programheaders.map((mapped, i) => (
                      <Table.Cell key={i}>
                        <img src={mapped.icon} />
                      </Table.Cell>
                    ))}
                </Table.Row>
              </Table>
            </Box>
          </Box>
          <Box style={{
              float: "right",
            }} left="5px">
            <Table>
              <Table.Row>
                {PC_light_name && (
                  <Table.Cell>
                    <Button
                      onClick={() =>
                        act('PC_toggle_component', {
                          component: PC_light_name,
                        })
                      }
                    />
                  </Table.Cell>
                )}
                <Table.Cell>
                  <Button
                    content="Shutdown"
                    onClick={() => act('PC_shutdown')}
                  />
                </Table.Cell>
              </Table.Row>
            </Table>
          </Box>
          <Box style={{
            clear: "both",
          }} />
          {has_gps && (
            <Box
              border-top-width="3px"
              border-top-style="double"
              border-top-color="#7B7B7B"
              p="0px"
            >
              <Table>
                <Table.Row>
                  <Table.Cell>
                    <img src={gps_icon} />
                  </Table.Cell>
                  <Table.Cell>{gps_data}</Table.Cell>
                </Table.Row>
              </Table>
            </Box>
          )}
        </Box>
      </Box>
      <Box id="uiTitleWrapper">
        <Box id="uiStatusIcon" className="icon24 uiStatusGood" />

        {PC_showexitprogram && (
          <Box id="uiTitleButtons">
            <Table>
              <Table.Row>
                <Table.Cell>
                  <Button
                    content="Exit Program"
                    onClick={() => act('PC_exit')}
                  />
                </Table.Cell>
                <Table.Cell>
                  <Button
                    content="Minimize Program"
                    onClick={() => act('PC_minimize')}
                  />
                </Table.Cell>
              </Table.Row>
            </Table>
          </Box>
        )}
        {PC_showexitprogram || <Box id="uiTitleFluff" />}
      </Box>
      <Box id="uiContent">
        <Box id="uiLoadingNotice">Initiating...</Box>
      </Box>
    </>
  );
};
