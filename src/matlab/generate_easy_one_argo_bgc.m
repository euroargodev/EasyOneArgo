% ------------------------------------------------------------------------------
% Generate Easy OneArgo BGC data sets
% (EasyOneArgoDOXY, EasyOneArgoNITRATE, EasyOneArgoPH, EasyOneArgoRADIOMETRY,
% EasyOneArgoCHLA_BBP and EasyOneArgoBGCLite).
%
% SYNTAX :
%   generate_easy_one_argo_bgc(varargin)
%
% INPUT PARAMETERS :
%   varargin :
%      input parameters:
%         - should be provided as pairs ('param_name','param_value')
%         - 'param_name' value is not case sensitive
%   no mandatory input parameters
%   possible input parameters:
%      inputDataDir            : top directory of input NetCDF files
%      inputMinMaxDir          : directory of min/max test csv files
%      inputDataDoi            : DOI of the input data set (Argo monthly snapshot)
%      csvOutputDir            : directory to store the CSV output data sets
%      logDir                  : directory to store the log file
%      xmlReportDir            : directory to store the XML report
%      xmlReportName           : file name of the XML report
%      generateOutputAuditFlag : flag to generate output audit files
%      auditOutputDir          : output audit files directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - V 0.1: creation
%   07/07/2026 - RNU - V 1.0: first deployed version
%   08/28/2026 - RNU - V 1.1: - update of index file headers (added the list of
%                             parameters for 'data_mode' information)
%                             - new selection for PTS data of BGCLite (Qc = '1',
%                             '2' or '8' instead of Qc = '1' in previous
%                             versions)
% ------------------------------------------------------------------------------
function generate_easy_one_argo_bgc(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF S-PROF files
% (top directory of the DAC name directories (as in the GDAC))
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\monoS_mini\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\monoS_20260628_92go\';

% directory of min/max test excluded profiles
% 3 files are expected:
%   - drift_latest_exclusion.csv
%   - drift_latest_new.csv
%   - drift_latest_previous_reports.csv
% in /home/oo26/coriolis/co05/co0508/etc/Report_ObjectiveAnalysisWarning/csv_drift 
% or https://data-argo.ifremer.fr/etc/Report_ObjectiveAnalysisWarning/csv_drift/
DIR_INPUT_MIN_MAX_CSV_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\IN\min_max_csv\';

% DOI of the reference input data set
INPUT_DATA_DOI = 'http://doi.org/10.17882/42182#114627';

% top directory of output CSV files
DIR_OUTPUT_CSV_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% generate output audit files
GENERATE_OUTPUT_AUDIT_FLAG = 1;

% top directory of output audit files
DIR_OUTPUT_AUDIT_FILES = 'C:\Users\jprannou\_DATA\ONE_ARGO_BGC\OUT_audit\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process a reduced number of input S-PROF files (set to -1 to process all the files)
global g_cogeoab_nbFilesToProcess;
g_cogeoab_nbFilesToProcess = -1;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;
g_cogeoab_generateEasyOneArgoBgcVersion = '1.1';

% berbose mode (for additionnal information on ignored data)
global g_cogeoab_verboseMode;
g_cogeoab_verboseMode = 0;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoab_minNbProfBeforeSaving;
g_cogeoab_minNbProfBeforeSaving = 5000;

% number of profiles in memory to allocate
global g_cogeoab_nbProfToAllocate;
g_cogeoab_nbProfToAllocate = 5000;

% input parameters
global g_cogeoab_dirInputNcFiles;
global g_cogeoab_dirInputMinMaxFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_xmlReportFileName;
global g_cogeoab_logFilePathName;
global g_cogeoab_generateOutputAuditFlag;
global g_cogeoab_dirOutputAuditFiles;

% store DAC name from input directories
global g_cogeoab_dacName;
g_cogeoab_dacName = '';

global g_cogeoab_janFirst1950InMatlab;
g_cogeoab_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% XML report information structure
global g_cogeoab_reportXmlData;
g_cogeoab_reportXmlData = [];

% date of the run
global g_cogeoab_nowUtc;
g_cogeoab_nowUtc = now_utc;
% g_cogeoab_nowUtc = datenum('20260420', 'yyyymmdd') % for comparison of 2 run results

global g_cogeoab_nowUtcStr;
g_cogeoab_nowUtcStr = datestr(g_cogeoab_nowUtc, 'yyyy-mm-ddTHH:MM:SSZ');

% number to create a unique Id for temporary output MAT file names
global g_cogeoab_tempoOutPutMatId;
g_cogeoab_tempoOutPutMatId = 1;


logFileName = [];
status = 'nok';
try

   % startTime
   ticStartTime = tic;

   % store the start time of the run
   currentTime = datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ');

   % init the XML report
   init_xml_report(currentTime);

   % get input parameters
   [inputError] = parse_input_param(varargin);

   if (inputError == 0)

      % set parameter default values
      if (isempty(g_cogeoab_dirInputNcFiles))
         g_cogeoab_dirInputNcFiles = DIR_INPUT_NC_FILES;
      end
      if (isempty(g_cogeoab_dirInputMinMaxFiles))
         g_cogeoab_dirInputMinMaxFiles = DIR_INPUT_MIN_MAX_CSV_FILES;
      end
      if (isempty(g_cogeoab_inputDataDoi))
         g_cogeoab_inputDataDoi = INPUT_DATA_DOI;
      end
      if (isempty(g_cogeoab_dirOutputCsvFiles))
         g_cogeoab_dirOutputCsvFiles = DIR_OUTPUT_CSV_FILES;
      end
      if (isempty(g_cogeoab_dirLogFile))
         g_cogeoab_dirLogFile = DIR_LOG_FILE;
      end
      if (isempty(g_cogeoab_dirOutputXmlFile))
         g_cogeoab_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cogeoab_generateOutputAuditFlag))
         g_cogeoab_generateOutputAuditFlag = GENERATE_OUTPUT_AUDIT_FLAG;
      end
      if (isempty(g_cogeoab_dirOutputAuditFiles))
         g_cogeoab_dirOutputAuditFiles = DIR_OUTPUT_AUDIT_FILES;
      end

      % log file creation
      if (~isempty(g_cogeoab_xmlReportFileName))
         logFileName = [g_cogeoab_dirLogFile '/generate_easy_one_argo_bgc_' g_cogeoab_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cogeoab_dirLogFile '/generate_easy_one_argo_bgc_' currentTime '.log'];
      end

      g_cogeoab_logFilePathName = logFileName;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % create the list of profiles to exclude (from min/max test)
      create_excluded_profile_list;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % process the files according to input and configuration parameters
      generate_easy_one_argo_bgc_;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);

   else
      g_cogeoab_dirOutputXmlFile = DIR_XML_FILE;
   end

catch

   diary off;

   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);

end

% create the XML report path file name
if (~isempty(g_cogeoab_xmlReportFileName))
   xmlFileName = [g_cogeoab_dirOutputXmlFile '/' g_cogeoab_xmlReportFileName];
else
   xmlFileName = [g_cogeoab_dirOutputXmlFile '/co05081602_' currentTime '.xml']; % TBD
end

% save the XML report
writer = matlab.io.xml.dom.DOMWriter;
writer.Configuration.FormatPrettyPrint = true;
writeToFile(writer, g_cogeoab_xmlReportDOMNode, xmlFileName);

% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Create the list of profiles that should be excluded from output dataset.
%
% There are 3 csv files of profiles excluded from min/max test:
%   - drift_latest_exclusion.csv
%   - drift_latest_new.csv
%   - drift_latest_previous_reports.csv
%
% they are stored in:
% in /home/oo26/coriolis/co05/co0508/etc/Report_ObjectiveAnalysisWarning/csv_drift 
% or https://data-argo.ifremer.fr/etc/Report_ObjectiveAnalysisWarning/csv_drift/
%
% SYNTAX :
%    create_excluded_profile_list
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/20/2026 - RNU - creation
% ------------------------------------------------------------------------------
function create_excluded_profile_list

% excluded profile info
global g_cogeoab_excluded_prof;
g_cogeoab_excluded_prof = [];

% input parameters
global g_cogeoab_dirInputMinMaxFiles;


for idLoop = 1:3
   if (idLoop == 1)
      fileName = 'drift_latest_exclusion.csv';
   elseif (idLoop == 2)
      fileName = 'drift_latest_new.csv';
   elseif (idLoop == 3)
      fileName = 'drift_latest_previous_reports.csv';
   end
   filePathName = [g_cogeoab_dirInputMinMaxFiles '/' fileName];
   if ~(exist(filePathName, 'file') == 2)
      fprintf('INFO: Missing  file : %s\n', filePathName);
      continue
   end

   warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
   dataTable = readtable(filePathName);
   warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');

   wmoList = dataTable(:, 'WMO').Variables;
   firstCycle = dataTable(:, 'FirstCycleInAlert').Variables;
   lastCycle = dataTable(:, 'LastCycleInAlert').Variables;
   dacList = dataTable(:, 'DAC').Variables;
   piList = dataTable(:, 'PI').Variables;
   piList = regexprep(piList, ' --> Exclusion List', '');
   piList = regexprep(piList, ' --> Exclusion list', '');

   for idL = 1:length(wmoList)
      if (~isnan(wmoList(idL)))
         if (~isnan(lastCycle(idL)))
            cycleList = firstCycle(idL):lastCycle(idL);
         else
            cycleList = firstCycle(idL);
         end
         if (~isempty(g_cogeoab_excluded_prof))
            idF = find([g_cogeoab_excluded_prof{:, 1}] == wmoList(idL));
            if (~isempty(idF))
               g_cogeoab_excluded_prof{idF, 2} = unique([g_cogeoab_excluded_prof{idF, 2} cycleList]);
            else
               g_cogeoab_excluded_prof{end+1, 1} = wmoList(idL);
               g_cogeoab_excluded_prof{end, 2} = cycleList;
               g_cogeoab_excluded_prof{end, 3} = dacList{idL};
               g_cogeoab_excluded_prof{end, 4} = piList{idL};
               g_cogeoab_excluded_prof{end, 5} = firstCycle(idL);
               g_cogeoab_excluded_prof{end, 6} = lastCycle(idL);
            end
         else
            g_cogeoab_excluded_prof{end+1, 1} = wmoList(idL);
            g_cogeoab_excluded_prof{end, 2} = cycleList;
            g_cogeoab_excluded_prof{end, 3} = dacList{idL};
            g_cogeoab_excluded_prof{end, 4} = piList{idL};
            g_cogeoab_excluded_prof{end, 5} = firstCycle(idL);
            g_cogeoab_excluded_prof{end, 6} = lastCycle(idL);
         end
      end
   end
end

if (~isempty(g_cogeoab_excluded_prof))
   [~, idSort] = sort([g_cogeoab_excluded_prof{:, 1}]);
   g_cogeoab_excluded_prof = g_cogeoab_excluded_prof(idSort, :);
end

return

% ------------------------------------------------------------------------------
% Generate Easy OneArgo BGC data sets
% (EasyOneArgoDOXY, EasyOneArgoNITRATE, EasyOneArgoPH, EasyOneArgoRADIOMETRY,
% EasyOneArgoCHLA_BBP and EasyOneArgoBGCLite).
%
% SYNTAX :
%    generate_easy_one_argo_bgc_
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function generate_easy_one_argo_bgc_

% input parameters
global g_cogeoab_dirInputNcFiles;
global g_cogeoab_dirInputMinMaxFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_logFilePathName;
global g_cogeoab_generateOutputAuditFlag;
global g_cogeoab_dirOutputAuditFiles;

% output directories
global g_cogeoab_dirOutputCsvFileBgc;
global g_cogeoab_dirOutputCsvFileBgcData;
global g_cogeoab_dirOutputCsvFileBgcLite;
global g_cogeoab_dirOutputCsvFileBgcLiteData;
global g_cogeoab_dirOutputCsvFileDoxy;
global g_cogeoab_dirOutputCsvFileDoxyData;
global g_cogeoab_dirOutputCsvFileNitrate;
global g_cogeoab_dirOutputCsvFileNitrateData;
global g_cogeoab_dirOutputCsvFilePh;
global g_cogeoab_dirOutputCsvFilePhData;
global g_cogeoab_dirOutputCsvFileChlaBbp;
global g_cogeoab_dirOutputCsvFileChlaBbpData;
global g_cogeoab_dirOutputCsvFileRadiometry;
global g_cogeoab_dirOutputCsvFileRadiometryData;
global g_cogeoab_dirOutputMatFile;

% index files
global g_cogeoab_indexFileBgc;
global g_cogeoab_indexFileBgcLite;
global g_cogeoab_indexFileDoxy;
global g_cogeoab_indexFileNitrate;
global g_cogeoab_indexFilePh;
global g_cogeoab_indexFileChlaBbp;
global g_cogeoab_indexFileRadiometry;

% user report files
global g_cogeoab_reportFileBgc;
global g_cogeoab_reportFileBgcLite;
global g_cogeoab_reportFileDoxy;
global g_cogeoab_reportFileNitrate;
global g_cogeoab_reportFilePh;
global g_cogeoab_reportFileChlaBbp;
global g_cogeoab_reportFileRadiometry;

% time of the processed dataset
global g_cogeoab_nowUtc;

% process a reduced number of input S-PROF files
global g_cogeoab_nbFilesToProcess;

% array of processed data
global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;
g_cogeoab_profTab = [];
g_cogeoab_profLiteTab = [];

% index in array of processed data
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;
g_cogeoab_profTabId = 1;
g_cogeoab_profLiteTabId = 1;

% minimum number of profiles in memory before creating associated CSV files
global g_cogeoab_minNbProfBeforeSaving;

% number of input files processed
global g_cogeoab_nbInputFiles;
g_cogeoab_nbInputFiles = 0;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;
g_cogeoab_nbInputProfiles = 0;

% number of output files generated
global g_cogeoab_nbOutputFilesBgc;
global g_cogeoab_nbOutputFilesBgcLite;
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesRadiometry;
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMatExpected;
global g_cogeoab_nbOutputProfMat;
g_cogeoab_nbOutputFilesBgc = 0;
g_cogeoab_nbOutputFilesBgcLite = 0;
g_cogeoab_nbOutputFilesDoxy = 0;
g_cogeoab_nbOutputFilesNitrate = 0;
g_cogeoab_nbOutputFilesPh = 0;
g_cogeoab_nbOutputFilesChlaBbp = 0;
g_cogeoab_nbOutputFilesRadiometry = 0;
g_cogeoab_nbOutputFilesMat = 0;
g_cogeoab_nbOutputProfMatExpected = 0;
g_cogeoab_nbOutputProfMat = 0;

% store DAC from input directories
global g_cogeoab_dacName;


diary(g_cogeoab_logFilePathName);
tic;

% print input parameter values in log file
fprintf('\nINPUT PARAMETERS:\n');
fprintf('DIR_INPUT_NC_FILES          : ''%s''\n', g_cogeoab_dirInputNcFiles);
fprintf('DIR_INPUT_MIN_MAX_CSV_FILES : ''%s''\n', g_cogeoab_dirInputMinMaxFiles);
fprintf('INPUT_DATA_DOI              : ''%s''\n', g_cogeoab_inputDataDoi);
fprintf('DIR_OUTPUT_CSV_FILES        : ''%s''\n', g_cogeoab_dirOutputCsvFiles);
fprintf('DIR_LOG_FILE                : ''%s''\n', g_cogeoab_dirLogFile);
fprintf('DIR_XML_FILE                : ''%s''\n', g_cogeoab_dirOutputXmlFile);
fprintf('GENERATE_OUTPUT_AUDIT_FLAG  : %d\n', g_cogeoab_generateOutputAuditFlag);
fprintf('DIR_OUTPUT_AUDIT_FILES      : ''%s''\n\n', g_cogeoab_dirOutputAuditFiles);

% load interpolation reference data
load_eoa_levels_ref;

% create output directories
if ~(exist(g_cogeoab_dirOutputCsvFiles, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFiles);
end
g_cogeoab_dirOutputCsvFileBgc = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoBGC_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileBgc, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgc);
end
g_cogeoab_dirOutputCsvFileBgcData = [g_cogeoab_dirOutputCsvFileBgc '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileBgcData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgcData);
end
g_cogeoab_dirOutputCsvFileBgcLite = [g_cogeoab_dirOutputCsvFiles '/EasyOneArgoBGCLite_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
if ~(exist(g_cogeoab_dirOutputCsvFileBgcLite, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgcLite);
end
g_cogeoab_dirOutputCsvFileBgcLiteData = [g_cogeoab_dirOutputCsvFileBgcLite '/data'];
if ~(exist(g_cogeoab_dirOutputCsvFileBgcLiteData, 'dir') == 7)
   mkdir(g_cogeoab_dirOutputCsvFileBgcLiteData);
end

if (g_cogeoab_generateOutputAuditFlag)
   if ~(exist(g_cogeoab_dirOutputAuditFiles, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputAuditFiles);
   end
   g_cogeoab_dirOutputCsvFileDoxy = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoDOXY_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputCsvFileDoxy, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileDoxy);
   end
   g_cogeoab_dirOutputCsvFileDoxyData = [g_cogeoab_dirOutputCsvFileDoxy '/data'];
   if ~(exist(g_cogeoab_dirOutputCsvFileDoxyData, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileDoxyData);
   end
   g_cogeoab_dirOutputCsvFileNitrate = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoNITRATE_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputCsvFileNitrate, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileNitrate);
   end
   g_cogeoab_dirOutputCsvFileNitrateData = [g_cogeoab_dirOutputCsvFileNitrate '/data'];
   if ~(exist(g_cogeoab_dirOutputCsvFileNitrateData, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileNitrateData);
   end
   g_cogeoab_dirOutputCsvFilePh = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoPH_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputCsvFilePh, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFilePh);
   end
   g_cogeoab_dirOutputCsvFilePhData = [g_cogeoab_dirOutputCsvFilePh '/data'];
   if ~(exist(g_cogeoab_dirOutputCsvFilePhData, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFilePhData);
   end
   g_cogeoab_dirOutputCsvFileChlaBbp = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoCHLA_BBP_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputCsvFileChlaBbp, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileChlaBbp);
   end
   g_cogeoab_dirOutputCsvFileChlaBbpData = [g_cogeoab_dirOutputCsvFileChlaBbp '/data'];
   if ~(exist(g_cogeoab_dirOutputCsvFileChlaBbpData, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileChlaBbpData);
   end
   g_cogeoab_dirOutputCsvFileRadiometry = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoRADIOMETRY_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputCsvFileRadiometry, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileRadiometry);
   end
   g_cogeoab_dirOutputCsvFileRadiometryData = [g_cogeoab_dirOutputCsvFileRadiometry '/data'];
   if ~(exist(g_cogeoab_dirOutputCsvFileRadiometryData, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputCsvFileRadiometryData);
   end
   g_cogeoab_dirOutputMatFile = [g_cogeoab_dirOutputAuditFiles '/EasyOneArgoBGCLite_audit_' datestr(g_cogeoab_nowUtc, 'yyyymmddTHHMMSSZ')];
   if ~(exist(g_cogeoab_dirOutputMatFile, 'dir') == 7)
      mkdir(g_cogeoab_dirOutputMatFile);
   end
end

% set index file names
g_cogeoab_indexFileBgc = [g_cogeoab_dirOutputCsvFileBgc '/EasyOneArgoBGC_index.csv'];
g_cogeoab_indexFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_index.csv'];
g_cogeoab_indexFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_index.csv'];
g_cogeoab_indexFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_index.csv'];
g_cogeoab_indexFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_index.csv'];
g_cogeoab_indexFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA_BBP_index.csv'];
g_cogeoab_indexFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_index.csv'];

% set report file names
g_cogeoab_reportFileBgc = [g_cogeoab_dirOutputCsvFileBgc '/EasyOneArgoBGC_report.txt'];
g_cogeoab_reportFileBgcLite = [g_cogeoab_dirOutputCsvFileBgcLite '/EasyOneArgoBGCLite_report.txt'];
g_cogeoab_reportFileDoxy = [g_cogeoab_dirOutputCsvFileDoxy '/EasyOneArgoDOXY_report.txt'];
g_cogeoab_reportFileNitrate = [g_cogeoab_dirOutputCsvFileNitrate '/EasyOneArgoNITRATE_report.txt'];
g_cogeoab_reportFilePh = [g_cogeoab_dirOutputCsvFilePh '/EasyOneArgoPH_report.txt'];
g_cogeoab_reportFileChlaBbp = [g_cogeoab_dirOutputCsvFileChlaBbp '/EasyOneArgoCHLA_BBP_report.txt'];
g_cogeoab_reportFileRadiometry = [g_cogeoab_dirOutputCsvFileRadiometry '/EasyOneArgoRADIOMETRY_report.txt'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process input directory

% input are mono-cycle S profile files
stop = 0;
dirNames = dir(g_cogeoab_dirInputNcFiles);
for idDir = 1:length(dirNames)

   if (stop)
      break
   end

   dacName = dirNames(idDir).name;
   if (strcmp(dacName, '.') || strcmp(dacName, '..'))
      continue
   end

   fprintf('Processing DAC %s:\n', dacName);
   g_cogeoab_dacName = dacName;

   floatDirPath = [g_cogeoab_dirInputNcFiles '/' dacName '/'];
   floatDirNames = dir(floatDirPath);
   for idFDir = 1:length(floatDirNames)

      if (stop)
         break
      end

      floatDirName = floatDirNames(idFDir).name;
      if (strcmp(floatDirName, '.') || strcmp(floatDirName, '..'))
         continue
      end

      fprintf('%04d/%04d %s\n', idFDir-2, length(floatDirNames)-2, floatDirName);

      % list of profiles for this float
      profFiles = dir([floatDirPath '/' floatDirName '/profiles/S*' floatDirName '*.nc']);

      % check that there is only one file ('SD*.nc' or 'SR*.nc') for each cycle
      % and direction + exclude profiles rejected by the min/max test
      profFiles = clean_profile_file_list(profFiles, str2double(floatDirName));

      % process remaining profiles
      for idFFile = 1:length(profFiles)

         profFilePathName = [floatDirPath '/' floatDirName '/profiles/' profFiles(idFFile).name];
         % fprintf('   %s\n', profFiles(idFFile).name);

         % process one file
         process_profile_s_file(profFilePathName);
         g_cogeoab_nbInputFiles = g_cogeoab_nbInputFiles + 1;

         if (g_cogeoab_profTabId > g_cogeoab_minNbProfBeforeSaving)
            % save the stored data in CSV files
            print_output_file;
         end

         if (g_cogeoab_nbInputFiles == g_cogeoab_nbFilesToProcess)
            stop = 1;
            break
         end
      end
   end
end

% save the remaining stored data in CSV files
print_output_file;

% concatenate output MAT files
concat_output_mat_files;

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Check that both 'D' and 'R' data mode mono-cycle S profiles are not present
% for the same cycle and direction (and remove the 'R' data mode ones from the
% list of profiles in such case).
% Exclude the profiles rejected by the min/max test.
%
% SYNTAX :
%  [o_profFiles] = clean_profile_file_list(a_profFiles, a_floatNum)
%
% INPUT PARAMETERS :
%   a_profFiles : input profile list
%   a_floatNum  : float WMO number
%
% OUTPUT PARAMETERS :
%   o_profFiles : output profile list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/16/2026 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profFiles] = clean_profile_file_list(a_profFiles, a_floatNum)

% output parameters initialization
o_profFiles = a_profFiles;

% excluded profile info
global g_cogeoab_excluded_prof;


% collect information on input profiles
profInfo = ones(length(o_profFiles), 3);
for idP = 1:length(o_profFiles)
   profFileName = o_profFiles(idP).name;
   idFus = strfind(profFileName, '_');
   cyNum = str2double(profFileName(idFus+1:idFus+3));
   if (any(strfind(profFileName, 'D.nc')))
      dir = 1;
   else
      dir = 2;
   end
   if (strcmp(profFileName(1:2), 'SD'))
      dm = 1;
   else
      dm = 0;
   end
   profInfo(idP, :) = [cyNum, dir, dm];
end

% check that 'D' and 'R' data modes are not simultaneously present for the same
% cycle and direction
profRtListId = find(profInfo(:, 3) == 0);
idDel = [];
for idP = profRtListId'
   if (any((profInfo(:, 1) == profInfo(idP, 1)) & ...
         (profInfo(:, 2) == profInfo(idP, 2)) & (profInfo(:, 3) == 1)))
      idDel = [idDel; idP];
   end
end

% excude profiles rejected by the min/max test
if (~isempty(g_cogeoab_excluded_prof))
   idF = find([g_cogeoab_excluded_prof{:, 1}] == a_floatNum);
   if (~isempty(idF))
      excludedCycleList = g_cogeoab_excluded_prof{idF, 2};
      idF = find((profInfo(:, 2) == 2) & (ismember(profInfo(:, 1), excludedCycleList)));
      idDel = [idDel; idF];
   end
end

o_profFiles(unique(idDel)) = [];

return

% ------------------------------------------------------------------------------
% Process one S file.
%
% SYNTAX :
% process_profile_s_file(a_profFilePathName)
%
% INPUT PARAMETERS :
%   a_profFilePathName : name of the file to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function process_profile_s_file(a_profFilePathName)

% array of processed data
global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;

% index in array of processed data
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;

% number of profiles in memory to allocate
global g_cogeoab_nbProfToAllocate;

% number of output files generated
global g_cogeoab_nbOutputProfMatExpected;

% default values
global g_cogeoab_janFirst1950InMatlab;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;

% input parameters
global g_cogeoab_generateOutputAuditFlag;

% defined levels of vertical interpolation grid
global g_cogeoab_eoaLevels;

% store DAC from input directories
global g_cogeoab_dacName;

% fillValue of LATITUDE and LONGITUDE (not retreive from NetCDF file to speed up
% the process)
LAT_LON_FV = double(99999);

% fillValue of all concerned measurements (not retrieved from NetCDF file to speed up the
% process)
MEAS_FV = single(99999);


% retrieve data from profile file
wantedVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PI_NAME'} ...
   {'STATION_PARAMETERS'} ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DATA_CENTRE'} ...
   {'PARAMETER_DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'PRES'} ...
   {'PRES_QC'} ...
   {'PRES_ADJUSTED'} ...
   {'PRES_ADJUSTED_QC'} ...
   {'PRES_ADJUSTED_ERROR'} ...
   {'TEMP'} ...
   {'TEMP_QC'} ...
   {'TEMP_ADJUSTED'} ...
   {'TEMP_ADJUSTED_QC'} ...
   {'TEMP_ADJUSTED_ERROR'} ...
   {'PSAL'} ...
   {'PSAL_QC'} ...
   {'PSAL_ADJUSTED'} ...
   {'PSAL_ADJUSTED_QC'} ...
   {'PSAL_ADJUSTED_ERROR'} ...
   {'DOXY_ADJUSTED'} ...
   {'DOXY_ADJUSTED_QC'} ...
   {'DOXY_ADJUSTED_ERROR'} ...
   {'NITRATE_ADJUSTED'} ...
   {'NITRATE_ADJUSTED_QC'} ...
   {'NITRATE_ADJUSTED_ERROR'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED_QC'} ...
   {'PH_IN_SITU_TOTAL_ADJUSTED_ERROR'} ...
   {'CHLA_ADJUSTED'} ...
   {'CHLA_ADJUSTED_QC'} ...
   {'CHLA_ADJUSTED_ERROR'} ...
   {'CHLA_FLUORESCENCE_ADJUSTED'} ...
   {'CHLA_FLUORESCENCE_ADJUSTED_QC'} ...
   {'CHLA_FLUORESCENCE_ADJUSTED_ERROR'} ...
   {'BBP700_ADJUSTED'} ...
   {'BBP700_ADJUSTED_QC'} ...
   {'BBP700_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE380_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE412_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE443_ADJUSTED'} ...
   {'DOWN_IRRADIANCE443_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE443_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE490_ADJUSTED_ERROR'} ...
   {'DOWN_IRRADIANCE555_ADJUSTED'} ...
   {'DOWN_IRRADIANCE555_ADJUSTED_QC'} ...
   {'DOWN_IRRADIANCE555_ADJUSTED_ERROR'} ...
   {'DOWNWELLING_PAR_ADJUSTED'} ...
   {'DOWNWELLING_PAR_ADJUSTED_QC'} ...
   {'DOWNWELLING_PAR_ADJUSTED_ERROR'} ...
   ];

if (g_cogeoab_generateOutputAuditFlag)
   wantedVars = [wantedVars ...
      {'DOXY'} ...
      {'NITRATE'} ...
      {'PH_IN_SITU_TOTAL'} ...
      {'CHLA'} ...
      {'CHLA_FLUORESCENCE'} ...
      {'BBP700'} ...
      {'DOWN_IRRADIANCE380'} ...
      {'DOWN_IRRADIANCE412'} ...
      {'DOWN_IRRADIANCE443'} ...
      {'DOWN_IRRADIANCE490'} ...
      {'DOWN_IRRADIANCE555'} ...
      {'DOWNWELLING_PAR'} ...
      ];
end

[profData] = get_data_from_nc_file(a_profFilePathName, wantedVars);

juldQc = get_data_from_name('JULD_QC', profData);
latitude = get_data_from_name('LATITUDE', profData);
longitude = get_data_from_name('LONGITUDE', profData);
positionQc = get_data_from_name('POSITION_QC', profData);
g_cogeoab_nbInputProfiles = g_cogeoab_nbInputProfiles + length(juldQc);

% TEMP TO CHECK INPUT CONSISTENCY - START
% idF = strfind(a_profFilePathName, '/');
% newPath = [a_profFilePathName(1:idF(end)) '/profiles/'];
% if (length(juldQc) ~= length(dir([newPath 'S*.nc'])))
%    fprintf('ERROR: INCONSISTENT %d VS %d : %s\n', ...
%       length(juldQc), ...
%       length(dir([newPath 'S*.nc'])), ...
%       a_profFilePathName);
% end
% return
% TEMP TO CHECK INPUT CONSISTENCY - STOP

% select 'good' profiles
idGoList = find(((juldQc == '1') | (juldQc == '5') | (juldQc == '8')) & ...
   ((positionQc == '1') | (positionQc == '5') | (positionQc == '8')) & ...
   ~((latitude == LAT_LON_FV) | (longitude == LAT_LON_FV))); % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV, Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
if (~isempty(idGoList))

   platformNumber = get_data_from_name('PLATFORM_NUMBER', profData)';
   piName = get_data_from_name('PI_NAME', profData)';
   stationParameters = get_data_from_name('STATION_PARAMETERS', profData);
   cycleNumber = get_data_from_name('CYCLE_NUMBER', profData);
   direction = get_data_from_name('DIRECTION', profData);
   dataCenter = get_data_from_name('DATA_CENTRE', profData)';
   paramDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData);
   paramDataMode = regexprep(paramDataMode', ' ', '-')';
   juld = get_data_from_name('JULD', profData);
   pres = get_data_from_name('PRES', profData);
   presQc = get_data_from_name('PRES_QC', profData);
   presAdj = get_data_from_name('PRES_ADJUSTED', profData);
   presAdjQc = get_data_from_name('PRES_ADJUSTED_QC', profData);
   presAdjErr = get_data_from_name('PRES_ADJUSTED_ERROR', profData);
   temp = get_data_from_name('TEMP', profData);
   tempQc = get_data_from_name('TEMP_QC', profData);
   tempAdj = get_data_from_name('TEMP_ADJUSTED', profData);
   tempAdjQc = get_data_from_name('TEMP_ADJUSTED_QC', profData);
   tempAdjErr = get_data_from_name('TEMP_ADJUSTED_ERROR', profData);
   psal = get_data_from_name('PSAL', profData);
   psalQc = get_data_from_name('PSAL_QC', profData);
   psalAdj = get_data_from_name('PSAL_ADJUSTED', profData);
   psalAdjQc = get_data_from_name('PSAL_ADJUSTED_QC', profData);
   psalAdjErr = get_data_from_name('PSAL_ADJUSTED_ERROR', profData);
   doxyAdj = get_data_from_name('DOXY_ADJUSTED', profData);
   doxyAdjQc = get_data_from_name('DOXY_ADJUSTED_QC', profData);
   doxyAdjErr = get_data_from_name('DOXY_ADJUSTED_ERROR', profData);
   nitrateAdj = get_data_from_name('NITRATE_ADJUSTED', profData);
   nitrateAdjQc = get_data_from_name('NITRATE_ADJUSTED_QC', profData);
   nitrateAdjErr = get_data_from_name('NITRATE_ADJUSTED_ERROR', profData);
   phAdj = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED', profData);
   phAdjQc = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED_QC', profData);
   phAdjErr = get_data_from_name('PH_IN_SITU_TOTAL_ADJUSTED_ERROR', profData);
   chlaAdj = get_data_from_name('CHLA_ADJUSTED', profData);
   chlaAdjQc = get_data_from_name('CHLA_ADJUSTED_QC', profData);
   chlaAdjErr = get_data_from_name('CHLA_ADJUSTED_ERROR', profData);
   chlaFluoAdj = get_data_from_name('CHLA_FLUORESCENCE_ADJUSTED', profData);
   chlaFluoAdjQc = get_data_from_name('CHLA_FLUORESCENCE_ADJUSTED_QC', profData);
   chlaFluoAdjErr = get_data_from_name('CHLA_FLUORESCENCE_ADJUSTED_ERROR', profData);
   bbp700Adj = get_data_from_name('BBP700_ADJUSTED', profData);
   bbp700AdjQc = get_data_from_name('BBP700_ADJUSTED_QC', profData);
   bbp700AdjErr = get_data_from_name('BBP700_ADJUSTED_ERROR', profData);
   downIrr380Adj = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED', profData);
   downIrr380AdjQc = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED_QC', profData);
   downIrr380AdjErr = get_data_from_name('DOWN_IRRADIANCE380_ADJUSTED_ERROR', profData);
   downIrr412Adj = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED', profData);
   downIrr412AdjQc = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED_QC', profData);
   downIrr412AdjErr = get_data_from_name('DOWN_IRRADIANCE412_ADJUSTED_ERROR', profData);
   downIrr443Adj = get_data_from_name('DOWN_IRRADIANCE443_ADJUSTED', profData);
   downIrr443AdjQc = get_data_from_name('DOWN_IRRADIANCE443_ADJUSTED_QC', profData);
   downIrr443AdjErr = get_data_from_name('DOWN_IRRADIANCE443_ADJUSTED_ERROR', profData);
   downIrr490Adj = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED', profData);
   downIrr490AdjQc = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED_QC', profData);
   downIrr490AdjErr = get_data_from_name('DOWN_IRRADIANCE490_ADJUSTED_ERROR', profData);
   downIrr555Adj = get_data_from_name('DOWN_IRRADIANCE555_ADJUSTED', profData);
   downIrr555AdjQc = get_data_from_name('DOWN_IRRADIANCE555_ADJUSTED_QC', profData);
   downIrr555AdjErr = get_data_from_name('DOWN_IRRADIANCE555_ADJUSTED_ERROR', profData);
   downwellingParAdj = get_data_from_name('DOWNWELLING_PAR_ADJUSTED', profData);
   downwellingParAdjQc = get_data_from_name('DOWNWELLING_PAR_ADJUSTED_QC', profData);
   downwellingParAdjErr = get_data_from_name('DOWNWELLING_PAR_ADJUSTED_ERROR', profData);

   % get the data mode of each parameter
   dataModePres = repmat('-', length(juld), 1);
   dataModeTemp = repmat('-', length(juld), 1);
   dataModePsal = repmat('-', length(juld), 1);
   dataModeDoxy = repmat('-', length(juld), 1);
   dataModeNitrate = repmat('-', length(juld), 1);
   dataModePh = repmat('-', length(juld), 1);
   dataModeChla = repmat('-', length(juld), 1);
   dataModeChlaFluo = repmat('-', length(juld), 1);
   dataModeBbp700 = repmat('-', length(juld), 1);
   dataModeDownIrr380 = repmat('-', length(juld), 1);
   dataModeDownIrr412 = repmat('-', length(juld), 1);
   dataModeDownIrr443 = repmat('-', length(juld), 1);
   dataModeDownIrr490 = repmat('-', length(juld), 1);
   dataModeDownIrr555 = repmat('-', length(juld), 1);
   dataModeDownwellingPar = repmat('-', length(juld), 1);
   [~, nParam, ~] = size(stationParameters);
   for idParam = 1:nParam
      for idProf = idGoList'
         paramName = strtrim(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            switch (paramName)
               case 'PRES'
                  dataModePres(idProf) = paramDataMode(idParam, idProf);
               case 'TEMP'
                  dataModeTemp(idProf) = paramDataMode(idParam, idProf);
               case 'PSAL'
                  dataModePsal(idProf) = paramDataMode(idParam, idProf);
               case 'DOXY'
                  dataModeDoxy(idProf) = paramDataMode(idParam, idProf);
               case 'NITRATE'
                  dataModeNitrate(idProf) = paramDataMode(idParam, idProf);
               case 'PH_IN_SITU_TOTAL'
                  dataModePh(idProf) = paramDataMode(idParam, idProf);
               case 'CHLA'
                  dataModeChla(idProf) = paramDataMode(idParam, idProf);
               case 'CHLA_FLUORESCENCE'
                  dataModeChlaFluo(idProf) = paramDataMode(idParam, idProf);
               case 'BBP700'
                  dataModeBbp700(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE380'
                  dataModeDownIrr380(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE412'
                  dataModeDownIrr412(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE443'
                  dataModeDownIrr443(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE490'
                  dataModeDownIrr490(idProf) = paramDataMode(idParam, idProf);
               case 'DOWN_IRRADIANCE555'
                  dataModeDownIrr555(idProf) = paramDataMode(idParam, idProf);
               case 'DOWNWELLING_PAR'
                  dataModeDownwellingPar(idProf) = paramDataMode(idParam, idProf);
            end
         end
      end
   end

   for idP = idGoList' % one loop for each S profile

      paramDataModeAll = [ ...
         dataModePres(idP), dataModeTemp(idP), dataModePsal(idP), ...
         dataModeDoxy(idP), dataModeNitrate(idP), dataModePh(idP), ...
         dataModeChla(idP), dataModeChlaFluo(idP), dataModeBbp700(idP), ...
         dataModeDownIrr380(idP), dataModeDownIrr412(idP), ...
         dataModeDownIrr443(idP), dataModeDownIrr490(idP), ...
         dataModeDownIrr555(idP), dataModeDownwellingPar(idP)];

      % PTS should be present
      if (any(ismember(paramDataModeAll(1:3), '-')))
         continue
      end
      % at least one BGC parameter in 'A' or 'D'
      if (all(ismember(paramDataModeAll(4:end), '-R')))
         continue
      end

      % put longitude in the [-180; 180[ interval
      if (longitude(idP) >= 180)
         longitude(idP) = longitude(idP) - 360;
      end
      if (longitude(idP) < -180)
         longitude(idP) = longitude(idP) + 360;
      end

      % get the 'best' PTS measurements for the current profile
      if ((dataModePres(idP) == 'A') || (dataModePres(idP) == 'D'))
         presBest = presAdj(:, idP);
         presBestQc = presAdjQc(:, idP);
         presBestErr = presAdjErr(:, idP);
      elseif (dataModePres(idP) == 'R')
         presBest = pres(:, idP);
         presBestQc = presQc(:, idP);
         presBestErr = ones(size(presBest))*MEAS_FV;
      end
      defaultData = ones(size(presBest))*MEAS_FV;
      defaultDataQc = repmat(' ', size(presBest));
      if ((dataModeTemp(idP) == 'A') || (dataModeTemp(idP) == 'D'))
         tempBest = tempAdj(:, idP);
         tempBestQc = tempAdjQc(:, idP);
         tempBestErr = tempAdjErr(:, idP);
      else
         tempBest = temp(:, idP);
         tempBestQc = tempQc(:, idP);
         tempBestErr = defaultData;
      end
      if ((dataModePsal(idP) == 'A') || (dataModePsal(idP) == 'D'))
         psalBest = psalAdj(:, idP);
         psalBestQc = psalAdjQc(:, idP);
         psalBestErr = psalAdjErr(:, idP);
      else
         psalBest = psal(:, idP);
         psalBestQc = psalQc(:, idP);
         psalBestErr = defaultData;
      end

      % get the BGC ADJUSTED measurements for the current profile
      if ((dataModeDoxy(idP) == 'A') || (dataModeDoxy(idP) == 'D'))
         doxyBest = doxyAdj(:, idP);
         doxyBestQc = doxyAdjQc(:, idP);
         doxyBestErr = doxyAdjErr(:, idP);
      else
         doxyBest = defaultData;
         doxyBestQc = defaultDataQc;
         doxyBestErr = defaultData;
      end
      if ((dataModeNitrate(idP) == 'A') || (dataModeNitrate(idP) == 'D'))
         nitrateBest = nitrateAdj(:, idP);
         nitrateBestQc = nitrateAdjQc(:, idP);
         nitrateBestErr = nitrateAdjErr(:, idP);
      else
         nitrateBest = defaultData;
         nitrateBestQc = defaultDataQc;
         nitrateBestErr = defaultData;
      end
      if ((dataModePh(idP) == 'A') || (dataModePh(idP) == 'D'))
         phBest = phAdj(:, idP);
         phBestQc = phAdjQc(:, idP);
         phBestErr = phAdjErr(:, idP);
      else
         phBest = defaultData;
         phBestQc = defaultDataQc;
         phBestErr = defaultData;
      end
      if ((dataModeChla(idP) == 'A') || (dataModeChla(idP) == 'D'))
         chlaBest = chlaAdj(:, idP);
         chlaBestQc = chlaAdjQc(:, idP);
         chlaBestErr = chlaAdjErr(:, idP);
      else
         chlaBest = defaultData;
         chlaBestQc = defaultDataQc;
         chlaBestErr = defaultData;
      end
      if ((dataModeChlaFluo(idP) == 'A') || (dataModeChlaFluo(idP) == 'D'))
         chlaFluoBest = chlaFluoAdj(:, idP);
         chlaFluoBestQc = chlaFluoAdjQc(:, idP);
         chlaFluoBestErr = chlaFluoAdjErr(:, idP);
      else
         chlaFluoBest = defaultData;
         chlaFluoBestQc = defaultDataQc;
         chlaFluoBestErr = defaultData;
      end
      if ((dataModeBbp700(idP) == 'A') || (dataModeBbp700(idP) == 'D'))
         bbp700Best = bbp700Adj(:, idP);
         bbp700BestQc = bbp700AdjQc(:, idP);
         bbp700BestErr = bbp700AdjErr(:, idP);
      else
         bbp700Best = defaultData;
         bbp700BestQc = defaultDataQc;
         bbp700BestErr = defaultData;
      end
      if ((dataModeDownIrr380(idP) == 'A') || (dataModeDownIrr380(idP) == 'D'))
         downIrr380Best = downIrr380Adj(:, idP);
         downIrr380BestQc = downIrr380AdjQc(:, idP);
         downIrr380BestErr = downIrr380AdjErr(:, idP);
      else
         downIrr380Best = defaultData;
         downIrr380BestQc = defaultDataQc;
         downIrr380BestErr = defaultData;
      end
      if ((dataModeDownIrr412(idP) == 'A') || (dataModeDownIrr412(idP) == 'D'))
         downIrr412Best = downIrr412Adj(:, idP);
         downIrr412BestQc = downIrr412AdjQc(:, idP);
         downIrr412BestErr = downIrr412AdjErr(:, idP);
      else
         downIrr412Best = defaultData;
         downIrr412BestQc = defaultDataQc;
         downIrr412BestErr = defaultData;
      end
      if ((dataModeDownIrr443(idP) == 'A') || (dataModeDownIrr443(idP) == 'D'))
         downIrr443Best = downIrr443Adj(:, idP);
         downIrr443BestQc = downIrr443AdjQc(:, idP);
         downIrr443BestErr = downIrr443AdjErr(:, idP);
      else
         downIrr443Best = defaultData;
         downIrr443BestQc = defaultDataQc;
         downIrr443BestErr = defaultData;
      end
      if ((dataModeDownIrr490(idP) == 'A') || (dataModeDownIrr490(idP) == 'D'))
         downIrr490Best = downIrr490Adj(:, idP);
         downIrr490BestQc = downIrr490AdjQc(:, idP);
         downIrr490BestErr = downIrr490AdjErr(:, idP);
      else
         downIrr490Best = defaultData;
         downIrr490BestQc = defaultDataQc;
         downIrr490BestErr = defaultData;
      end
      if ((dataModeDownIrr555(idP) == 'A') || (dataModeDownIrr555(idP) == 'D'))
         downIrr555Best = downIrr555Adj(:, idP);
         downIrr555BestQc = downIrr555AdjQc(:, idP);
         downIrr555BestErr = downIrr555AdjErr(:, idP);
      else
         downIrr555Best = defaultData;
         downIrr555BestQc = defaultDataQc;
         downIrr555BestErr = defaultData;
      end
      if ((dataModeDownwellingPar(idP) == 'A') || (dataModeDownwellingPar(idP) == 'D'))
         downwellingParBest = downwellingParAdj(:, idP);
         downwellingParBestQc = downwellingParAdjQc(:, idP);
         downwellingParBestErr = downwellingParAdjErr(:, idP);
      else
         downwellingParBest = defaultData;
         downwellingParBestQc = defaultDataQc;
         downwellingParBestErr = defaultData;
      end

      rawData = [ ...
         presBest, tempBest, psalBest, ...
         doxyBest, nitrateBest, phBest, ...
         chlaBest, chlaFluoBest, bbp700Best, ...
         downIrr380Best, downIrr412Best, ...
         downIrr443Best, downIrr490Best, ...
         downIrr555Best, downwellingParBest];
      rawDataErr = [ ...
         presBestErr, tempBestErr, psalBestErr, ...
         doxyBestErr, nitrateBestErr, phBestErr, ...
         chlaBestErr, chlaFluoBestErr, bbp700BestErr, ...
         downIrr380BestErr, downIrr412BestErr, ...
         downIrr443BestErr, downIrr490BestErr, ...
         downIrr555BestErr, downwellingParBestErr];
      % convert Qc char into integers
      strTmp = repmat('@', size(presBestQc));
      rawDataQc = [ ...
         presBestQc, strTmp, tempBestQc, strTmp, psalBestQc, strTmp, ...
         doxyBestQc, strTmp, nitrateBestQc, strTmp, phBestQc, strTmp, ...
         chlaBestQc, strTmp, chlaFluoBestQc, strTmp, bbp700BestQc, strTmp, ...
         downIrr380BestQc, strTmp, downIrr412BestQc, strTmp, ...
         downIrr443BestQc, strTmp, downIrr490BestQc, strTmp, ...
         downIrr555BestQc, strTmp, downwellingParBestQc];
      rawDataQc(rawDataQc == ' ') =  '7'; % QC='7' not used in Argo
      rawDataQc(rawDataQc == '@') =  ' '; % preserve spaces for str2num
      rawDataQc = str2num(rawDataQc);

      if (g_cogeoab_generateOutputAuditFlag)
         doxy = get_data_from_name('DOXY', profData);
         if (isempty(doxy))
            doxy = defaultData;
         end
         nitrate = get_data_from_name('NITRATE', profData);
         if (isempty(nitrate))
            nitrate = defaultData;
         end
         ph = get_data_from_name('PH_IN_SITU_TOTAL', profData);
         if (isempty(ph))
            ph = defaultData;
         end
         chla = get_data_from_name('CHLA', profData);
         if (isempty(chla))
            chla = defaultData;
         end
         chlaFluo = get_data_from_name('CHLA_FLUORESCENCE', profData);
         if (isempty(chlaFluo))
            chlaFluo = defaultData;
         end
         bbp700 = get_data_from_name('BBP700', profData);
         if (isempty(bbp700))
            bbp700 = defaultData;
         end
         downIrr380 = get_data_from_name('DOWN_IRRADIANCE380', profData);
         if (isempty(downIrr380))
            downIrr380 = defaultData;
         end
         downIrr412 = get_data_from_name('DOWN_IRRADIANCE412', profData);
         if (isempty(downIrr412))
            downIrr412 = defaultData;
         end
         downIrr443 = get_data_from_name('DOWN_IRRADIANCE443', profData);
         if (isempty(downIrr443))
            downIrr443 = defaultData;
         end
         downIrr490 = get_data_from_name('DOWN_IRRADIANCE490', profData);
         if (isempty(downIrr490))
            downIrr490 = defaultData;
         end
         downIrr555 = get_data_from_name('DOWN_IRRADIANCE555', profData);
         if (isempty(downIrr555))
            downIrr555 = defaultData;
         end
         downwellingPar = get_data_from_name('DOWNWELLING_PAR', profData);
         if (isempty(downwellingPar))
            downwellingPar = defaultData;
         end

         matRawDataO = [ ...
            pres, temp, psal, ...
            doxy, nitrate, ph, ...
            chla, chlaFluo, bbp700, ...
            downIrr380, downIrr412, ...
            downIrr443, downIrr490, ...
            downIrr555, downwellingPar];
         matRawData = rawData;
         matRawDataQc = [ ...
            presBestQc, tempBestQc, psalBestQc, ...
            doxyBestQc, nitrateBestQc, phBestQc, ...
            chlaBestQc, chlaFluoBestQc, bbp700BestQc, ...
            downIrr380BestQc, downIrr412BestQc, ...
            downIrr443BestQc, downIrr490BestQc, ...
            downIrr555BestQc, downwellingParBestQc];
      end

      data1 = [];
      data1Err = [];
      data2 = [];
      data2Err = [];
      data3 = [];
      data3Err = [];
      data4 = [];
      data4Err = [];
      data5 = [];
      data5Err = [];
      for loopNumber = 1:6 % one loop for each BGC dataset + the concatenated one

         switch (loopNumber)
            case 1
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'DOXY'}];
               paramDataMode = paramDataModeAll([1:3 4]);
               % keep only BGC measurements with data mode = 'A' or 'D'
               if ((paramDataModeAll(4) == '-') || (paramDataModeAll(4) == 'R'))
                  continue
               end

               data = rawData(:, [1:3 4]);
               dataErr = rawDataErr(:, [1:3 4]);
               dataQc = rawDataQc(:, [1:3 4]);

               % remove padding levels
               idDel = find(sum(dataQc == 7, 2) == length(parameterList));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];

               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;

               dataErr(isnan(data)) = nan;
               
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';
               
               data1 = data;
               data1Err = dataErr;

               if (~g_cogeoab_generateOutputAuditFlag)
                  continue
               end

            case 2
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'NITRATE'}];
               paramDataMode = paramDataModeAll([1:3 5]);
               % keep only BGC measurements with data mode = 'A' or 'D'
               if ((paramDataModeAll(5) == '-') || (paramDataModeAll(5) == 'R'))
                  continue
               end

               data = rawData(:, [1:3 5]);
               dataErr = rawDataErr(:, [1:3 5]);
               dataQc = rawDataQc(:, [1:3 5]);

               % remove padding levels
               idDel = find(sum(dataQc == 7, 2) == length(parameterList));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];

               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;

               dataErr(isnan(data)) = nan;
               
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';
               
               data2 = data;
               data2Err = dataErr;

               if (~g_cogeoab_generateOutputAuditFlag)
                  continue
               end

            case 3
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'PH_IN_SITU_TOTAL'}];
               paramDataMode = paramDataModeAll([1:3 6]);
               % keep only BGC measurements with data mode = 'A' or 'D'
               if ((paramDataModeAll(6) == '-') || (paramDataModeAll(6) == 'R'))
                  continue
               end

               data = rawData(:, [1:3 6]);
               dataErr = rawDataErr(:, [1:3 6]);
               dataQc = rawDataQc(:, [1:3 6]);

               % remove padding levels
               idDel = find(sum(dataQc == 7, 2) == length(parameterList));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];

               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;

               dataErr(isnan(data)) = nan;
               
               % keep only levels where all measurements are provided
               idDel = find(any(isnan(data), 2));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';
               
               data3 = data;
               data3Err = dataErr;

               if (~g_cogeoab_generateOutputAuditFlag)
                  continue
               end

            case 4
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} {'CHLA'} {'CHLA_FLUORESCENCE'} {'BBP700'}];
               paramDataMode = paramDataModeAll([1:3 7:9]);
               % be sure that at least one BGC parameter is present with data mode = 'A' or 'D'
               if (all(ismember(paramDataModeAll(7:9), '-R')))
                  continue
               end

               data = rawData(:, [1:3 7:9]);
               dataErr = rawDataErr(:, [1:3 7:9]);
               dataQc = rawDataQc(:, [1:3 7:9]);

               % remove padding levels
               idDel = find(sum(dataQc == 7, 2) == length(parameterList));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];

               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' or '5' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data(((dataQc(:, 4) ~= 1) & (dataQc(:, 4) ~= 5)), 4) = nan;
               data(((dataQc(:, 5) ~= 1) & (dataQc(:, 5) ~= 5)), 5) = nan;
               data(((dataQc(:, 6) ~= 1) & (dataQc(:, 6) ~= 5)), 6) = nan;

               dataErr(isnan(data)) = nan;

               % keep only levels where all PTS and at least one BGC measurements are provided
               idDel1 = find(any(isnan(data(:, 1:3)), 2)); % for PTS
               idDel2 = find(sum(isnan(data(:, 4:end)), 2) == size(data(:, 4:end), 2)); % for BGC
               idDel = unique([idDel1; idDel2]);
               data(idDel, :) = [];
               dataErr(idDel, :) = [];

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';

               data4 = data;
               data4Err = dataErr;

               if (~g_cogeoab_generateOutputAuditFlag)
                  continue
               end

            case 5
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} ...
                  {'DOWN_IRRADIANCE380'} {'DOWN_IRRADIANCE412'} ...
                  {'DOWN_IRRADIANCE443'} {'DOWN_IRRADIANCE490'} ...
                  {'DOWN_IRRADIANCE555'} {'DOWNWELLING_PAR'}];
               paramDataMode = paramDataModeAll([1:3 10:15]);
               % be sure that at least one BGC parameter is present with data mode = 'A' or 'D'
               if (all(ismember(paramDataModeAll(10:15), '-R')))
                  continue
               end

               data = rawData(:, [1:3 10:15]);
               dataErr = rawDataErr(:, [1:3 10:15]);
               dataQc = rawDataQc(:, [1:3 10:15]);

               % remove padding levels
               idDel = find(sum(dataQc == 7, 2) == length(parameterList));
               data(idDel, :) = [];
               dataErr(idDel, :) = [];
               dataQc(idDel, :) = [];

               data(data == MEAS_FV) = nan;
               dataErr(dataErr == MEAS_FV) = nan;

               % keep only Qc = '1', '2' or '8' for PTS data
               % keep only Qc = '1' for BGC data
               data(((dataQc(:, 1) ~= 1) & (dataQc(:, 1) ~= 2) & (dataQc(:, 1) ~= 8)), 1) = nan;
               data(((dataQc(:, 2) ~= 1) & (dataQc(:, 2) ~= 2) & (dataQc(:, 2) ~= 8)), 2) = nan;
               data(((dataQc(:, 3) ~= 1) & (dataQc(:, 3) ~= 2) & (dataQc(:, 3) ~= 8)), 3) = nan;
               data((dataQc(:, 4) ~= 1), 4) = nan;
               data((dataQc(:, 5) ~= 1), 5) = nan;
               data((dataQc(:, 6) ~= 1), 6) = nan;
               data((dataQc(:, 7) ~= 1), 7) = nan;
               data((dataQc(:, 8) ~= 1), 8) = nan;
               data((dataQc(:, 9) ~= 1), 9) = nan;

               dataErr(isnan(data)) = nan;

               % keep only levels where all PTS and at least one BGC measurements are provided
               idDel1 = find(any(isnan(data(:, 1:3)), 2)); % for PTS
               idDel2 = find(sum(isnan(data(:, 4:end)), 2) == size(data(:, 4:end), 2)); % for BGC
               idDel = unique([idDel1; idDel2]);
               data(idDel, :) = [];
               dataErr(idDel, :) = [];

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';

               data5 = data;
               data5Err = dataErr;

               if (~g_cogeoab_generateOutputAuditFlag)
                  continue
               end

            case 6
               parameterList = [{'PRES'} {'TEMP'} {'PSAL'} ...
                  {'DOXY'} {'NITRATE'} {'PH_IN_SITU_TOTAL'} ...
                  {'CHLA'} {'CHLA_FLUORESCENCE'} {'BBP700'} ...
                  {'DOWN_IRRADIANCE380'} {'DOWN_IRRADIANCE412'} ...
                  {'DOWN_IRRADIANCE443'} {'DOWN_IRRADIANCE490'} ...
                  {'DOWN_IRRADIANCE555'} {'DOWNWELLING_PAR'}];
               paramDataMode = paramDataModeAll;

               % concatenate PRES levels
               presData = [];
               presNum = [];
               for id = 1:5
                  if (id == 1)
                     if (~isempty(data1))
                        presData = [presData; data1(:, 1)];
                        presNum = [presNum; ones(size(data1(:, 1)))];
                     end
                  elseif (id == 2)
                     if (~isempty(data2))
                        presData = [presData; data2(:, 1)];
                        presNum = [presNum; ones(size(data2(:, 1)))*2];
                     end
                  elseif (id == 3)
                     if (~isempty(data3))
                        presData = [presData; data3(:, 1)];
                        presNum = [presNum; ones(size(data3(:, 1)))*3];
                     end
                  elseif (id == 4)
                     if (~isempty(data4))
                        presData = [presData; data4(:, 1)];
                        presNum = [presNum; ones(size(data4(:, 1)))*4];
                     end
                  elseif (id == 5)
                     if (~isempty(data5))
                        presData = [presData; data5(:, 1)];
                        presNum = [presNum; ones(size(data5(:, 1)))*5];
                     end
                  end
               end

               % create final PRES axis
               [presData, ~, ic] = unique(presData);
               data = nan(length(presData), length(parameterList));
               dataErr = nan(length(presData), length(parameterList));
               data(:, 1) = presData;

               % fill data array
               for id = 1:5
                  if (id == 1)
                     if (~isempty(data1))
                        idMap = ic(presNum == 1);
                        data(idMap, [2:3 4]) = data1(:, 2:end);
                        dataErr(idMap, [1:3 4]) = data1Err;
                     end
                  elseif (id == 2)
                     if (~isempty(data2))
                        idMap = ic(presNum == 2);
                        data(idMap, [2:3 5]) = data2(:, 2:end);
                        dataErr(idMap, [1:3 5]) = data2Err;
                     end
                  elseif (id == 3)
                     if (~isempty(data3))
                        idMap = ic(presNum == 3);
                        data(idMap, [2:3 6]) = data3(:, 2:end);
                        dataErr(idMap, [1:3 6]) = data3Err;
                     end
                  elseif (id == 4)
                     if (~isempty(data4))
                        idMap = ic(presNum == 4);
                        data(idMap, [2:3 7:9]) = data4(:, 2:end);
                        dataErr(idMap, [1:3 7:9]) = data4Err;
                     end
                  elseif (id == 5)
                     if (~isempty(data5))
                        idMap = ic(presNum == 5);
                        data(idMap, [2:3 10:15]) = data5(:, 2:end);
                        dataErr(idMap, [1:3 10:15]) = data5Err;
                     end
                  end
               end

               % update paramDataMode according to remaining values
               idColNoData = find(sum(isnan(data), 1) == size(data, 1));
               paramDataMode(idColNoData) = '-';
         end

         if (~isempty(data))

            profStruct = get_prof_data_init_struct;
            profStruct.loopNumber = loopNumber;
            profStruct.wmo = num2str(str2double(strtrim(platformNumber(idP, :)))); % issue whith AOML/1901501
            profStruct.dac = dataCenter(idP, :);
            profStruct.cyNum = cycleNumber(idP);
            profStruct.cyNumStr = num2str(cycleNumber(idP));
            profStruct.dir = upper(direction(idP));
            profStruct.parameterList = parameterList;
            profStruct.paramDataMode = paramDataMode;
            profStruct.juld = juld(idP);
            profStruct.juldStr = datestr(juld(idP)+g_cogeoab_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
            profStruct.lat = latitude(idP);
            profStruct.latStr = sprintf('%.5f', latitude(idP));
            profStruct.lon = longitude(idP);
            profStruct.lonStr = sprintf('%.5f', longitude(idP));
            profStruct.data = data;
            profStruct.dataMaxPres = max(data(:, 1));
            profStruct.dataErr = dataErr;

            % store output profile information

            if (isempty(g_cogeoab_profTab) || (g_cogeoab_profTabId > length(g_cogeoab_profTab)))
               g_cogeoab_profTab = cat(2, g_cogeoab_profTab, ...
                  repmat(get_prof_data_init_struct, 1, g_cogeoab_nbProfToAllocate));
            end

            g_cogeoab_profTab(g_cogeoab_profTabId) = profStruct;
            g_cogeoab_profTabId = g_cogeoab_profTabId + 1;
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % process raw data for the EasyOneArgoBGCLite

      % remove padding levels
      idDel = find(sum(rawDataQc == 7, 2) == size(rawData, 2));
      rawData(idDel, :) = [];
      rawDataErr(idDel, :) = [];
      rawDataQc(idDel, :) = [];
      if (g_cogeoab_generateOutputAuditFlag)
         matRawDataO(idDel, :) = [];
         matRawData(idDel, :) = [];
         matRawDataQc(idDel, :) = [];
      end

      if (~isempty(rawData))

         rawData(rawData == MEAS_FV) = nan;
         rawDataErr(rawDataErr == MEAS_FV) = nan;
         if (g_cogeoab_generateOutputAuditFlag)
            matRawDataO(matRawDataO == MEAS_FV) = nan;
            matRawData(matRawData == MEAS_FV) = nan;
         end

         % apply QC criteria on each parameter individually
         for idParam = 1:15
            if (idParam <= 3)
               % Qc or ADJUSTED_QC = '1', '2' or '8' for PTS data
               rawData(((rawDataQc(:, idParam) ~= 1) & (rawDataQc(:, idParam) ~= 2) & (rawDataQc(:, idParam) ~= 8)), idParam) = nan;
            elseif ((idParam >= 7) && (idParam <= 9))
               % ADJUSTED_QC = b 1b  or b 5b  for CHLA & BBP
               rawData(((rawDataQc(:, idParam) ~= 1) & (rawDataQc(:, idParam) ~= 5)), idParam) = nan;
            else
               % ADJUSTED_QC = b 1b  for PTS and other other BGC parameters
               rawData((rawDataQc(:, idParam) ~= 1), idParam) = nan;
            end
         end

         % P, T and S should be present
         % don't set P to nan because it can be used by one BGC parameter
         rawData(any(isnan(rawData(:, 1:3)), 2), 2) = nan; % set TEMP to nan
         rawData(any(isnan(rawData(:, 1:3)), 2), 3) = nan; % set PSAL to nan

         rawDataErr(isnan(rawData)) = nan;

         % remove useless levels
         idDel = find(sum(isnan(rawData(:, 2:end)), 2) == size(rawData(:, 2:end), 2));
         rawData(idDel, :) = [];
         rawDataErr(idDel, :) = [];

         % update paramDataModeAll according to remaining values
         idColNoData = find(sum(isnan(rawData), 1) == size(rawData, 1));
         paramDataModeAll(idColNoData) = '-';
         
         % list of existing parameter value
         paramIdList = any(~isnan(rawData), 1);

         % P, T, S and at least one BGC parameter should be present
         if ((sum(paramIdList(1:3)) == 3) && (sum(paramIdList) > 3))

            profStruct = get_prof_data_init_struct;
            profStruct.loopNumber = loopNumber;
            profStruct.wmo = num2str(str2double(strtrim(platformNumber(idP, :)))); % issue whith AOML/1901501
            profStruct.dac = dataCenter(idP, :);
            profStruct.cyNum = cycleNumber(idP);
            profStruct.cyNumStr = num2str(cycleNumber(idP));
            profStruct.dir = upper(direction(idP));
            profStruct.parameterList = [];
            profStruct.paramDataModeAll = paramDataModeAll;
            profStruct.juld = juld(idP);
            profStruct.juldStr = datestr(juld(idP)+g_cogeoab_janFirst1950InMatlab, 'yyyy-mm-ddTHH:MM:SSZ');
            profStruct.lat = latitude(idP);
            profStruct.latStr = sprintf('%.5f', latitude(idP));
            profStruct.lon = longitude(idP);
            profStruct.lonStr = sprintf('%.5f', longitude(idP));
            profStruct.rawDataParamId = paramIdList;
            profStruct.rawData = rawData;
            profStruct.rawDataErr = rawDataErr;
            profStruct.dataGridParamId = zeros(1, size(rawData, 2));
            profStruct.dataGrid = nan(length(g_cogeoab_eoaLevels), size(rawData, 2));
            profStruct.dataGridErr = nan(length(g_cogeoab_eoaLevels), size(rawData, 2));

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % interpolate data mesurements on a vertical grid

            profStruct = interpolate_data(profStruct);

            % P, T, S and at least one BGC parameter should be present
            if ((sum(profStruct.dataGridParamId(1:3)) == 3) && (sum(profStruct.dataGridParamId) > 3))

               % store output profile information

               if (isempty(g_cogeoab_profLiteTab) || (g_cogeoab_profLiteTabId > length(g_cogeoab_profLiteTab)))
                  g_cogeoab_profLiteTab = cat(2, g_cogeoab_profLiteTab, ...
                     repmat(get_prof_data_init_struct, 1, g_cogeoab_nbProfToAllocate));
               end

               g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId) = profStruct;

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % store additionnal information for MAT output

               if (~isempty(profStruct.dataMat))
                  % we need T,S and at least one BGC parameter
                  if (~isempty(profStruct.dataMat.templite) && ...
                        (~isempty(profStruct.dataMat.doxylite) || ...
                        ~isempty(profStruct.dataMat.nitratelite) || ...
                        ~isempty(profStruct.dataMat.phinsitutotallite) || ...
                        ~isempty(profStruct.dataMat.chlalite) || ...
                        ~isempty(profStruct.dataMat.chlafluorescencelite) || ...
                        ~isempty(profStruct.dataMat.bbp700lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance380lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance412lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance443lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance490lite) || ...
                        ~isempty(profStruct.dataMat.downirradiance555lite) || ...
                        ~isempty(profStruct.dataMat.downwellingparlite)))

                     wmoBox = pos_to_wmo(longitude(idP), latitude(idP));
                     if (~isnan(wmoBox))

                        profStruct.dataMat.wmoBox = wmoBox;
                        piNameVal = regexprep(strtrim(piName(idP, :)), ' ', '');
                        profStruct.dataMat.source = ...
                           {sprintf('%s_%03d.%s.%s', ...
                           strtrim(platformNumber(idP, :)), ...
                           cycleNumber(idP), ...
                           g_cogeoab_dacName, ...
                           piNameVal)};
                        profStruct.dataMat.dates = ...
                           {datestr(juld(idP) + g_cogeoab_janFirst1950InMatlab, 'yyyymmddHHMMSS')};
                        profStruct.dataMat.lat = latitude(idP);
                        long360 = longitude(idP);
                        if (long360 < 0)
                           long360 = long360 + 360;
                        end
                        profStruct.dataMat.long = long360;

                        profStruct.dataMat.nbLev = size(matRawDataO, 1);

                        if (isempty(profStruct.dataMat.doxylite))
                           profStruct.dataMat.doxylite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.nitratelite))
                           profStruct.dataMat.nitratelite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.phinsitutotallite))
                           profStruct.dataMat.phinsitutotallite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.chlalite))
                           profStruct.dataMat.chlalite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.chlafluorescencelite))
                           profStruct.dataMat.chlafluorescencelite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.bbp700lite))
                           profStruct.dataMat.bbp700lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance380lite))
                           profStruct.dataMat.downirradiance380lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance412lite))
                           profStruct.dataMat.downirradiance412lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance443lite))
                           profStruct.dataMat.downirradiance443lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance490lite))
                           profStruct.dataMat.downirradiance490lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downirradiance555lite))
                           profStruct.dataMat.downirradiance555lite = nan(length(g_cogeoab_eoaLevels), 1);
                        end
                        if (isempty(profStruct.dataMat.downwellingparlite))
                           profStruct.dataMat.downwellingparlite = nan(length(g_cogeoab_eoaLevels), 1);
                        end

                        profStruct.dataMat.preso = matRawDataO(:, 1);
                        profStruct.dataMat.tempo = matRawDataO(:, 2);
                        profStruct.dataMat.salo = matRawDataO(:, 3);
                        profStruct.dataMat.doxyo = matRawDataO(:, 4);
                        profStruct.dataMat.nitrateo = matRawDataO(:, 5);
                        profStruct.dataMat.phinsitutotalo = matRawDataO(:, 6);
                        profStruct.dataMat.chlao = matRawDataO(:, 7);
                        profStruct.dataMat.chlafluorescenceo = matRawDataO(:, 8);
                        profStruct.dataMat.bbp700o = matRawDataO(:, 9);
                        profStruct.dataMat.downirradiance380o = matRawDataO(:, 10);
                        profStruct.dataMat.downirradiance412o = matRawDataO(:, 11);
                        profStruct.dataMat.downirradiance443o = matRawDataO(:, 12);
                        profStruct.dataMat.downirradiance490o = matRawDataO(:, 13);
                        profStruct.dataMat.downirradiance555o = matRawDataO(:, 14);
                        profStruct.dataMat.downwellingparo = matRawDataO(:, 15);

                        profStruct.dataMat.presadj = matRawData(:, 1);
                        profStruct.dataMat.tempadj = matRawData(:, 2);
                        profStruct.dataMat.saladj = matRawData(:, 3);
                        profStruct.dataMat.doxyadj = matRawData(:, 4);
                        profStruct.dataMat.nitrateadj = matRawData(:, 5);
                        profStruct.dataMat.phinsitutotaladj = matRawData(:, 6);
                        profStruct.dataMat.chlaadj = matRawData(:, 7);
                        profStruct.dataMat.chlafluorescenceadj = matRawData(:, 8);
                        profStruct.dataMat.bbp700adj = matRawData(:, 9);
                        profStruct.dataMat.downirradiance380adj = matRawData(:, 10);
                        profStruct.dataMat.downirradiance412adj = matRawData(:, 11);
                        profStruct.dataMat.downirradiance443adj = matRawData(:, 12);
                        profStruct.dataMat.downirradiance490adj = matRawData(:, 13);
                        profStruct.dataMat.downirradiance555adj = matRawData(:, 14);
                        profStruct.dataMat.downwellingparadj = matRawData(:, 15);

                        profStruct.dataMat.presadjqc = matRawDataQc(:, 1);
                        profStruct.dataMat.tempadjqc = matRawDataQc(:, 2);
                        profStruct.dataMat.saladjqc = matRawDataQc(:, 3);
                        profStruct.dataMat.doxyadjqc = matRawDataQc(:, 4);
                        profStruct.dataMat.nitrateadjqc = matRawDataQc(:, 5);
                        profStruct.dataMat.phinsitutotaladjqc = matRawDataQc(:, 6);
                        profStruct.dataMat.chlaadjqc = matRawDataQc(:, 7);
                        profStruct.dataMat.chlafluorescenceadjqc = matRawDataQc(:, 8);
                        profStruct.dataMat.bbp700adjqc = matRawDataQc(:, 9);
                        profStruct.dataMat.downirradiance380adjqc = matRawDataQc(:, 10);
                        profStruct.dataMat.downirradiance412adjqc = matRawDataQc(:, 11);
                        profStruct.dataMat.downirradiance443adjqc = matRawDataQc(:, 12);
                        profStruct.dataMat.downirradiance490adjqc = matRawDataQc(:, 13);
                        profStruct.dataMat.downirradiance555adjqc = matRawDataQc(:, 14);
                        profStruct.dataMat.downwellingparadjqc = matRawDataQc(:, 15);

                        g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = profStruct.dataMat;

                        g_cogeoab_nbOutputProfMatExpected = g_cogeoab_nbOutputProfMatExpected + 1;
                     else

                        % not sure to select all location inconsistencies
                        % already managed inconsistencies are:
                        % AOML 4901542 #245A positionQc=8 and latitude=longitude=FV
                        % Coriolis 6902829 #102A positionQc=1 and latitude=longitude=FV
                        fprintf('ERROR: Bad location for float #%s cycle#%d%c - present in CSV output but not in MAT output\n', ...
                           profStruct.wmo, ...
                           profStruct.cyNum, ...
                           profStruct.dir);

                        g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = [];
                     end
                  else
                     % we need T,S and at least one BGC parameter; if not then remove dataMat
                     g_cogeoab_profLiteTab(g_cogeoab_profLiteTabId).dataMat = [];
                  end
               end

               g_cogeoab_profLiteTabId = g_cogeoab_profLiteTabId + 1;
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate PTS and BGC data on a vertical grid.
%
% SYNTAX :
%  [o_profStruct] = interpolate_data(a_profStruct)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation (from "Annie Wong, January 2024" code)
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_data(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;


% interpolate T&S data on the vertical grid
o_profStruct = interpolate_pts_data(o_profStruct);

% T, S are mandatory
if (sum(o_profStruct.dataGridParamId(1:3)) == 3)

   % interpolate BGC data on the vertical grid
   for paramId = 4:size(o_profStruct.rawData, 2)

      if (o_profStruct.rawDataParamId(paramId) == 1)

         switch (paramId)
            case {4, 5, 6} % DOXY, NITRATE, PH_IN_SITU_TOTAL

               o_profStruct = interpolate_bgc_data(o_profStruct, paramId);

            case {7, 8, 9} % CHLA, CHLA_FLUORESCENCE, BBP700

               % apply a median filter before interpolation
               rawDataTmp =  o_profStruct.rawData(:, paramId);
               o_profStruct.rawData(:, paramId) = apply_median_filter( ...
                  o_profStruct.rawData(:, 1), o_profStruct.rawData(:, paramId));

               if (any(~isnan(o_profStruct.rawData(:, paramId))))
                  o_profStruct = interpolate_bgc_data(o_profStruct, paramId);
               end

               o_profStruct.rawData(:, paramId) = rawDataTmp;

            case {10, 11, 12, 13, 14, 15} % DOWN_IRRADIANCE380, DOWN_IRRADIANCE412, DOWN_IRRADIANCE443, DOWN_IRRADIANCE490, DOWN_IRRADIANCE555, DOWNWELLING_PAR

               % transform to logarithmic before interpolation
               rawDataTmp =  o_profStruct.rawData(:, paramId);
               o_profStruct.rawData(:, paramId) = log(o_profStruct.rawData(:, paramId));

               o_profStruct = interpolate_bgc_data(o_profStruct, paramId);

               if (o_profStruct.dataGridParamId(paramId) == 1)
                  o_profStruct.dataGrid(:, paramId) = exp(1).^o_profStruct.dataGrid(:, paramId);
               end
               o_profStruct.rawData(:, paramId) = rawDataTmp;

         end
      end
   end

   % useful levels should have T, S and at least one BGC parameter
   idToNan = find(any(isnan(o_profStruct.dataGrid(:, 2:3)), 2) | ...
      all(isnan(o_profStruct.dataGrid(:, 4:end)), 2));
   if (~isempty(idToNan))
      o_profStruct.dataGrid(idToNan, 2:end) = nan(length(idToNan), size(o_profStruct.dataGrid, 2)-1);
      o_profStruct.dataGridErr(idToNan, :) = nan(length(idToNan), size(o_profStruct.dataGridErr, 2));
   end

   % remove levels below the deepest useful one
   idNan = find(any(isnan(o_profStruct.dataGrid(:, 2:3)), 2) | ...
      all(isnan(o_profStruct.dataGrid(:, 4:end)), 2));
   if (any(idNan == size(o_profStruct.dataGrid, 1)))
      firstUsefulUd = find(diff(flipud(idNan)) ~= -1, 1, 'first');
      if (~isempty(firstUsefulUd))
         lastUseful = size(o_profStruct.dataGrid, 1) - firstUsefulUd;
      else
         lastUseful = idNan(1) - 1;
      end
      o_profStruct.dataGrid(lastUseful+1:end, :) = [];
      o_profStruct.dataGridErr(lastUseful+1:end, :) = [];
   end
   o_profStruct.dataGridMaxPres = max(o_profStruct.dataGrid(:, 1));

   % update dataGridParamId and paramDataModeAll
   o_profStruct.dataGridParamId = any(~isnan(o_profStruct.dataGrid), 1);
   o_profStruct.paramDataModeAll(o_profStruct.dataGridParamId == 0) = '-';
end

return

% ------------------------------------------------------------------------------
% Interpolate profile PTS data on a vertical grid.
%
% SYNTAX :
%  [o_profStruct] = interpolate_pts_data(a_profStruct)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation (from "Annie Wong, January 2024" code)
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_pts_data(a_profStruct)

% output parameters initialization
o_profStruct = a_profStruct;

% defined levels of vertical interpolation grid
global g_cogeoab_eoaLevels;
global g_cogeoab_eoaUBoundLevel;
global g_cogeoab_eoaLBoundLevel;

% berbose mode (for additionnal information on ignored data)
global g_cogeoab_verboseMode;

% input parameters
global g_cogeoab_generateOutputAuditFlag;


inputData = a_profStruct.rawData(:, 1:3);
inputDataErr = a_profStruct.rawDataErr(:, 1:3);
idNoDef = find(sum(~isnan(inputData), 2) == 3); % P, T and S should be present

if (~isempty(idNoDef))

   idGood = find(inputData(idNoDef, 1) > 0); % BM2020 does not support negative pressures
   pres = inputData(idNoDef(idGood), 1);
   temp = inputData(idNoDef(idGood), 2);
   psal = inputData(idNoDef(idGood), 3);
   paramErr = inputDataErr(idNoDef(idGood), 1:3);

   if (length(pres) > 4) % BM2020 requires at least 5 points

      % BM2020 requires pressure increases monotonically
      % consider increasing pressures only (we start the algorithm from the
      % middle of the profile)
      idToDel = [];
      idStart = fix(length(pres)/2);
      pMin = pres(idStart);
      for id = idStart-1:-1:1
         if (pres(id) >= pMin)
            idToDel = [idToDel id];
         else
            pMin = pres(id);
         end
      end
      pMax = pres(idStart);
      for id = idStart+1:length(pres)
         if (pres(id) <= pMax)
            idToDel = [idToDel id];
         else
            pMax = pres(id);
         end
      end
      pres(idToDel) = [];
      temp(idToDel) = [];
      psal(idToDel) = [];
      paramErr(idToDel, :) = [];

      if (length(pres) > 4) % BM2020 requires at least 5 points

         eoaLevels = g_cogeoab_eoaLevels;
         eoaUBoundLevel = g_cogeoab_eoaUBoundLevel;
         eoaLBoundLevel = g_cogeoab_eoaLBoundLevel;

         [SA, ~] = gsw_SA_from_SP(psal, pres, a_profStruct.lon, a_profStruct.lat);
         CT = gsw_CT_from_t(SA, temp, pres);
         [SA_i, CT_i] = gsw_SA_CT_interp(SA, CT, pres, eoaLevels);
         [S_i, ~] = gsw_SP_from_SA(SA_i, eoaLevels, a_profStruct.lon, a_profStruct.lat);
         T_i = gsw_t_from_CT(SA_i, CT_i, eoaLevels);
         tInSitu = T_i;
         sPractical = S_i;

         % count the number of measurements in each "box"
         counts = hist(pres, eoaLevels - 0.001); % - 0.001 so that the lower boundary is excluded
         % update counts in first/last "box"
         counts(1) = counts(1) - length(find(pres < eoaUBoundLevel));
         counts(end) = counts(end) - length(find(pres >= eoaLBoundLevel));

         % remove interpolated/extrapolated points here there are no original
         % data within the "box"
         idNoMeas = find(counts == 0);
         tInSitu(idNoMeas) = nan;
         sPractical(idNoMeas) = nan;

         % remove extrapolated points deeper than MaxP + 1%
         idTooDeep = find(eoaLevels > 1.01*max(pres));
         tInSitu(idTooDeep) = nan;
         sPractical(idTooDeep) = nan;

         % manage parameter error
         griddedParamErr = nan(size(eoaLevels, 1), 3);

         intParamList = [];
         for id = 1:3
            if (all(~isnan(paramErr(:, id))))
               if (isscalar(unique(paramErr(:, id))))
                  griddedParamErr(:, id) = paramErr(1, id); % error constant
               else
                  intParamList = [intParamList, id]; % error not constant
               end
            end
         end

         if (~isempty(intParamList))

            % we need to find the levels of each grid PRES neighbors in input data
            idAbove = nan(size(eoaLevels));
            idBelow = nan(size(eoaLevels));
            idCheckList = find((eoaLevels >= min(pres)) & (eoaLevels <= max(pres)));
            for id = idCheckList'
               lev = eoaLevels(id);
               idA = find(pres <= lev, 1, 'last');
               idB = find(pres >= lev, 1, 'first');
               if (~isempty(idA) && ~isempty(idB))
                  idAbove(id) = idA;
                  idBelow(id) = idB;
               end
            end

            for idInt = intParamList
               idOkList = find(~isnan(idAbove) & ~isnan(idBelow));
               for id = idOkList'
                  % grided param error value = max value of surrounding neighbors
                  griddedParamErr(id, idInt) = max(paramErr(idAbove(id), idInt), paramErr(idBelow(id), idInt));
               end
            end
         end

         % set EasyOneArgoBGCLite CSV output parameter
         dataGridPts = [eoaLevels, tInSitu, sPractical];
         idToNan = find(any(isnan(dataGridPts(:, 2:3)), 2)); % TS should be defined for each level
         dataGridPts(idToNan, 2:3) = nan(length(idToNan), 2);
         if (any(~isnan(dataGridPts(:, 2))))

            % TS levels remain in the grid => store it in the output structure
            o_profStruct.dataGrid(:, 1:3) = dataGridPts;

            % update and store parameter error
            idToNan = find(isnan(dataGridPts(:, 2)));
            griddedParamErr(idToNan, 1:3) = nan(length(idToNan), 3);
            o_profStruct.dataGridErr(:, 1:3) = griddedParamErr;

            o_profStruct.dataGridParamId(1:3) = 1;

            % set EasyOneArgoBGCLite_audit MAT output parameter
            if (g_cogeoab_generateOutputAuditFlag)
               if ((o_profStruct.dir == 'A') && ...
                     ((o_profStruct.paramDataModeAll(1) == 'A') || (o_profStruct.paramDataModeAll(1) == 'D')))

                  o_profStruct.dataMat = get_mat_prof_data_init_struct;
                  o_profStruct.dataMat.templite = dataGridPts(:, 2);
                  o_profStruct.dataMat.sallite = dataGridPts(:, 3);
               end
            end
         end
      else
         if (g_cogeoab_verboseMode)
            fprintf('INFO: Profile %s_%s_%c not interpolated (only %d levels)\n', ...
               a_profStruct.wmo, ...
               a_profStruct.cyNumStr, ...
               a_profStruct.dir, ...
               length(pres));
         end
      end
   else
      if (g_cogeoab_verboseMode)
         fprintf('INFO: Profile %s_%s_%c not interpolated (only %d levels)\n', ...
            a_profStruct.wmo, ...
            a_profStruct.cyNumStr, ...
            a_profStruct.dir, ...
            length(pres));
      end
   end
end

return

% ------------------------------------------------------------------------------
% Interpolate BGC data on a vertical grid (linear interpolation).
%
% SYNTAX :
%  [o_profStruct] = interpolate_bgc_data(a_profStruct, a_paramId)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile data
%   a_paramId    : index of the parameter data in the input data array
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = interpolate_bgc_data(a_profStruct, a_paramId)

% output parameters initialization
o_profStruct = a_profStruct;

% input parameters
global g_cogeoab_generateOutputAuditFlag;

% defined levels of vertical interpolation grid
global g_cogeoab_eoaLevels;
global g_cogeoab_eoaUBoundLevel;
global g_cogeoab_eoaLBoundLevel;


eoaLevels = g_cogeoab_eoaLevels;
eoaUBoundLevel = g_cogeoab_eoaUBoundLevel;
eoaLBoundLevel = g_cogeoab_eoaLBoundLevel;

presVal = a_profStruct.rawData(:, 1);
paramVal = a_profStruct.rawData(:, a_paramId);
paramErr = a_profStruct.rawDataErr(:, a_paramId);

idNoDef = find(~isnan(presVal) & ~isnan(paramVal)); % P and BGC parameter should be present
presVal = presVal(idNoDef);
paramVal = paramVal(idNoDef);
paramErr = paramErr(idNoDef);

if (length(presVal) > 1)

   % consider increasing pressures only (we start the algorithm from the middle
   % of the profile)
   idToNan = [];
   idStart = fix(length(presVal)/2);
   pMin = presVal(idStart);
   for id = idStart-1:-1:1
      if (presVal(id) >= pMin)
         idToNan = [idToNan id];
      else
         pMin = presVal(id);
      end
   end
   pMax = presVal(idStart);
   for id = idStart+1:length(presVal)
      if (presVal(id) <= pMax)
         idToNan = [idToNan id];
      else
         pMax = presVal(id);
      end
   end
   presVal(idToNan) = nan;
   paramVal(idToNan) = nan;
   paramErr(idToNan) = nan;

   idNoDef = find(~isnan(presVal) & ~isnan(paramVal));
   presVal = presVal(idNoDef);
   paramVal = paramVal(idNoDef);
   paramErr = paramErr(idNoDef);
end

if (~isempty(presVal))

   paramInt = nan(size(eoaLevels));
   paramIntErr = nan(size(eoaLevels));

   if (length(presVal) > 1)

      % interpolate PARAM values
      paramInt = interp1(presVal, paramVal, eoaLevels, 'linear', 'extrap');

      % count the number of measurements in each "box"
      counts = hist(presVal, eoaLevels - 0.001); % - 0.001 so that the lower boundary is excluded
      % update counts in first/last "box"
      counts(1) = counts(1) - length(find(presVal < eoaUBoundLevel));
      counts(end) = counts(end) - length(find(presVal >= eoaLBoundLevel));

      % remove interpolated/extrapolated points here there are no original
      % data within the "box"
      idNoMeas = find(counts == 0);
      paramInt(idNoMeas) = nan;

      % remove extrapolated points deeper than MaxP + 1%
      idTooDeep = find(eoaLevels > 1.01*max(presVal));
      paramInt(idTooDeep) = nan;

      % manage parameter error
      if (all(~isnan(paramErr)))
         if (isscalar(unique(paramErr)))
            paramIntErr(~isnan(paramInt)) = unique(paramErr); % error constant
         else

            % we need to find the levels of each grid PRES neighbors in input data
            idAbove = nan(size(eoaLevels));
            idBelow = nan(size(eoaLevels));
            idCheckList = find((eoaLevels >= min(presVal)) & (eoaLevels <= max(presVal)));
            for id = idCheckList'
               lev = eoaLevels(id);
               idA = find(presVal <= lev, 1, 'last');
               idB = find(presVal >= lev, 1, 'first');
               if (~isempty(idA) && ~isempty(idB))
                  idAbove(id) = idA;
                  idBelow(id) = idB;
               end
            end

            idOkList = find(~isnan(idAbove) & ~isnan(idBelow));
            for id = idOkList'
               % grided param error value = max value of surrounding neighbors
               paramIntErr(id) = max(paramErr(idAbove(id)), paramErr(idBelow(id)));
            end
         end
      end

   elseif (any(eoaLevels == presVal))

      idF = find(eoaLevels == presVal);
      paramInt(idF) = paramVal;
      paramIntErr(idF) = paramErr;
   end

   if (any(~isnan(paramInt)))

      % set EasyOneArgoBGCLite CSV output parameter
      o_profStruct.dataGridParamId(:, a_paramId) = 1;
      o_profStruct.dataGrid(:, a_paramId) = paramInt;
      paramIntErr(isnan(paramInt)) = nan;
      o_profStruct.dataGridErr(:, a_paramId) = paramIntErr;

      % set EasyOneArgoBGCLite_audit MAT output parameter
      if (g_cogeoab_generateOutputAuditFlag)
         if (~isempty(o_profStruct.dataMat)) % probably useless
            if ((o_profStruct.dir == 'A') && ...
                  ((o_profStruct.paramDataModeAll(a_paramId) == 'A') || (o_profStruct.paramDataModeAll(a_paramId) == 'D')))

               switch (a_paramId)
                  case {4} % DOXY
                     o_profStruct.dataMat.doxylite = paramInt;
                  case {5} % NITRATE
                     o_profStruct.dataMat.nitratelite = paramInt;
                  case {6} % PH_IN_SITU_TOTAL
                     o_profStruct.dataMat.phinsitutotallite = paramInt;
                  case {7} % CHLA
                     o_profStruct.dataMat.chlalite = paramInt;
                  case {8} % CHLA_FLUORESCENCE
                     o_profStruct.dataMat.chlafluorescencelite = paramInt;
                  case {9} % BBP700
                     o_profStruct.dataMat.bbp700lite = paramInt;
                  case {10} % DOWN_IRRADIANCE380
                     o_profStruct.dataMat.downirradiance380lite = exp(1).^paramInt;
                  case {11} % DOWN_IRRADIANCE412
                     o_profStruct.dataMat.downirradiance412lite = exp(1).^paramInt;
                  case {12} % DOWN_IRRADIANCE443
                     o_profStruct.dataMat.downirradiance443lite = exp(1).^paramInt;
                  case {13} % DOWN_IRRADIANCE490
                     o_profStruct.dataMat.downirradiance490lite = exp(1).^paramInt;
                  case {14} % DOWN_IRRADIANCE555
                     o_profStruct.dataMat.downirradiance555lite = exp(1).^paramInt;
                  case {15} % DOWNWELLING_PAR
                     o_profStruct.dataMat.downwellingparlite = exp(1).^paramInt;
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Compute adaptative median filter of a set of values.
%
% SYNTAX :
%  [o_profDataFilt] = apply_median_filter(a_profPres, a_profData)
%
% INPUT PARAMETERS :
%   a_profPres : input PRES data
%   a_profData : input BGC data
%
% OUTPUT PARAMETERS :
%   o_profDataFilt : filtered BGC data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataFilt] = apply_median_filter(a_profPres, a_profData)

% output parameters initialization
o_profDataFilt = nan(size(a_profData));


% valid levels of the BGC profile
idNoNan = find(~isnan(a_profPres) & ~isnan(a_profData));
if (~isempty(idNoNan))

   profRes = median(diff(a_profPres(idNoNan)));
   if (profRes <= 1)
      filterSize = 11;
   elseif (profRes < 3)
      filterSize = 7;
   else
      filterSize = 5;
   end

   o_profDataFilt(idNoNan) = median_filter(a_profData(idNoNan), filterSize);
end

return

% ------------------------------------------------------------------------------
% Compute median values of a set of data.
%
% SYNTAX :
%  [o_dataFiltVal] = median_filter(a_dataVal, a_size)
%
% INPUT PARAMETERS :
%   a_dataVal : input set of values
%   a_size    : size of the median filter
%
% OUTPUT PARAMETERS :
%   o_dataFiltVal : median values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataFiltVal] = median_filter(a_dataVal, a_size)

% output parameters initialization
o_dataFiltVal = nan(size(a_dataVal));

halfSize = fix(a_size/2);
for id = 1:length(a_dataVal)
   id1 = max(1, id-halfSize);
   id2 = min(length(a_dataVal), id+halfSize);
   o_dataFiltVal(id) = median(a_dataVal(id1:id2));
end

return

% ------------------------------------------------------------------------------
% Print output CSV files.
%
% SYNTAX :
%    print_output_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function print_output_file

% output directories
global g_cogeoab_dirOutputCsvFileBgcData;
global g_cogeoab_dirOutputCsvFileBgcLiteData;
global g_cogeoab_dirOutputCsvFileDoxyData;
global g_cogeoab_dirOutputCsvFileNitrateData;
global g_cogeoab_dirOutputCsvFilePhData;
global g_cogeoab_dirOutputCsvFileChlaBbpData;
global g_cogeoab_dirOutputCsvFileRadiometryData;
global g_cogeoab_dirOutputMatFile;

% index files
global g_cogeoab_indexFileBgc;
global g_cogeoab_indexFileBgcLite;
global g_cogeoab_indexFileDoxy;
global g_cogeoab_indexFileNitrate;
global g_cogeoab_indexFilePh;
global g_cogeoab_indexFileChlaBbp;
global g_cogeoab_indexFileRadiometry;

global g_cogeoab_nowUtcStr;
global g_cogeoab_inputDataDoi;

global g_cogeoab_profTab;
global g_cogeoab_profLiteTab;
global g_cogeoab_profTabId;
global g_cogeoab_profLiteTabId;

% number of output files generated
global g_cogeoab_nbOutputFilesBgc;
global g_cogeoab_nbOutputFilesBgcLite;
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesRadiometry;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;

% number to create a unique Id for temporary output MAT file names
global g_cogeoab_tempoOutPutMatId;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGC CSV data files

indexCellStr = cell(g_cogeoab_profTabId-1, 2);
indexCellStrCpt = 1;
for idProf = 1:g_cogeoab_profTabId-1
   prof = g_cogeoab_profTab(idProf);

   if (~isempty(prof.data))

      header = cell(16, 1);
      header{1} = '#format = EasyOneArgoBGC';
      header{2} = ['#creation_date = ' g_cogeoab_nowUtcStr];
      header{3} = '#creation_centre = Ifremer';
      header{4} = '#creation_centre_pid = https://ror.org/044jxhp58';
      header{5} = ['#data_source_doi = ' g_cogeoab_inputDataDoi];
      header{6} = ['#data_centre = ' get_extended_data_center(prof.dac)];
      header{7} = ['#platform_number = ' prof.wmo];
      header{8} = ['#cycle_number = ' prof.cyNumStr];
      header{9} = ['#direction_of_profile (''A'' : ascending, ''D'' : descending) = ' prof.dir];
      header{10} = ['#parameter_data_mode (listed in order of the parameters in the header, ''D'' : delayed-mode, ''A'' : adjusted in real-time, ''-'' : parameter not available) = ' prof.paramDataMode];
      header{11} = ['#profile_date = ' prof.juldStr];
      header{12} = ['#profile_latitude = ' prof.latStr];
      header{13} = ['#profile_longitude = ' prof.lonStr];
      header{14} = '#pressure = sea water pressure equals 0 at sea-level';
      header{15} = '#temperature = sea temperature in-situ ITS-90 scale';
      header{16} = '#salinity = practical salinity';

      switch (prof.loopNumber)
         case 1
            header{17} = '#oxygen = dissolved oxygen';
            header{18} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'oxygen (micromole/kg),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'oxygen_error (micromole/kg)'];
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileDoxyData;
            csvFileSpecificName = 'EasyDOXY.csv';

         case 2
            header{17} = '#nitrate = nitrate';
            header{18} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'nitrate (micromole/kg),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'nitrate_error (micromole/kg)'];
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileNitrateData;
            csvFileSpecificName = 'EasyNITRATE.csv';

         case 3
            header{17} = '#pH = seawater pH reported on total scale';
            header{18} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'pH (dimensionless),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'pH_error (dimensionless)'];
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.4f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFilePhData;
            csvFileSpecificName = 'EasyPH.csv';

         case 4
            header{17} = '#chla = chlorophyll-A';
            header{18} = '#chlaFluorescence = chlorophyll-A fluorescence with factory calibration';
            header{19} = '#bbp700 = particle backscattering at 700 nanometers';
            header{20} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'chla (mg/m3),chlaFluorescence (ru),bbp700 (m-1),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'chla_error (mg/m3),chlaFluorescence_error (ru),bbp700_error (m-1)'];
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.4f'} {',%.7f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.4f'} {',%.4f'} {',%.7f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileChlaBbpData;
            csvFileSpecificName = 'EasyCHLA_BBP.csv';

         case 5
            header{17} = '#downIrr380 = downwelling irradiance at 380 nanometers';
            header{18} = '#downIrr412 = downwelling irradiance at 412 nanometers';
            header{19} = '#downIrr443 = downwelling irradiance at 443 nanometers';
            header{20} = '#downIrr490 = downwelling irradiance at 490 nanometers';
            header{21} = '#downIrr555 = downwelling irradiance at 555 nanometers';
            header{22} = '#downwellingPar = downwelling photosynthetic available radiation';
            header{23} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'downIrr380 (W/m^2/nm),downIrr412 (W/m^2/nm),downIrr443 (W/m^2/nm),downIrr490 (W/m^2/nm),downIrr555 (W/m^2/nm),downwellingPar (microMoleQuanta/m^2/sec),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'downIrr380_error (W/m^2/nm),downIrr412_error (W/m^2/nm),downIrr443_error (W/m^2/nm),downIrr490_error (W/m^2/nm),downIrr555_error (W/m^2/nm),downwellingPar_error (microMoleQuanta/m^2/sec)'];
            fmtParam = [{'%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.2f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileRadiometryData;
            csvFileSpecificName = 'EasyRADIOMETRY.csv';

         case 6
            header{17} = '#oxygen = dissolved oxygen';
            header{18} = '#nitrate = nitrate';
            header{19} = '#pH = seawater pH reported on total scale';
            header{20} = '#chla = chlorophyll-A';
            header{21} = '#chlaFluorescence = chlorophyll-A fluorescence with factory calibration';
            header{22} = '#bbp700 = particle backscattering at 700 nanometers';
            header{23} = '#downIrr380 = downwelling irradiance at 380 nanometers';
            header{24} = '#downIrr412 = downwelling irradiance at 412 nanometers';
            header{25} = '#downIrr443 = downwelling irradiance at 443 nanometers';
            header{26} = '#downIrr490 = downwelling irradiance at 490 nanometers';
            header{27} = '#downIrr555 = downwelling irradiance at 555 nanometers';
            header{28} = '#downwellingPar = downwelling photosynthetic available radiation';
            header{29} = [ ...
               'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
               'oxygen (micromole/kg),'...
               'nitrate (micromole/kg),' ...
               'pH (dimensionless),' ...
               'chla (mg/m3),chlaFluorescence (ru),bbp700 (m-1),'...
               'downIrr380 (W/m^2/nm),downIrr412 (W/m^2/nm),downIrr443 (W/m^2/nm),downIrr490 (W/m^2/nm),downIrr555 (W/m^2/nm),downwellingPar (microMoleQuanta/m^2/sec),' ...
               'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
               'oxygen_error (micromole/kg),'...
               'nitrate_error (micromole/kg),' ...
               'pH_error (dimensionless),' ...
               'chla_error (mg/m3),chlaFluorescence_error (ru),bbp700_error (m-1),' ...
               'downIrr380_error (W/m^2/nm),downIrr412_error (W/m^2/nm),downIrr443_error (W/m^2/nm),downIrr490_error (W/m^2/nm),downIrr555_error (W/m^2/nm),downwellingPar_error (microMoleQuanta/m^2/sec)'];
            fmtParam = [ ...
               {'%.2f'} {',%.3f'} {',%.3f'} ...
               {',%.3f'} ...
               {',%.3f'} ...
               {',%.4f'} ...
               {',%.4f'} {',%.4f'} {',%.7f'} ...
               {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} ...
               {',%.2f'} {',%.3f'} {',%.3f'} ...
               {',%.3f'} ...
               {',%.3f'} ...
               {',%.4f'} ...
               {',%.4f'} {',%.4f'} {',%.7f'} ...
               {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'}];
            dirOutputCsvFileData = g_cogeoab_dirOutputCsvFileBgcData;
            csvFileSpecificName = 'EasyBGC.csv';
      end

      dataStr = cell(size(prof.data, 1), 1);
      data = [prof.data, prof.dataErr];
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [dirOutputCsvFileData '/' prof.wmo];
      if ~(exist(dirOutputCsvFloatName, 'dir') == 7)
         mkdir(dirOutputCsvFloatName);
      end

      % create output CSV file
      if (prof.dir == 'A')
         profDirStr = '';
      else
         profDirStr = 'D';
      end
      csvFileBaseName = sprintf('%s_%03d%c_', prof.wmo, prof.cyNum, profDirStr);
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName csvFileSpecificName];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);

      % store index data
      indexStr = sprintf('%s,%s,%s,%c,%s,%s,%s,%s,%.2f', ...
         prof.dac, ...
         prof.wmo, ...
         prof.cyNumStr, ...
         prof.dir, ...
         prof.paramDataMode, ...
         prof.juldStr, ...
         prof.latStr, ...
         prof.lonStr, ...
         prof.dataMaxPres);
      indexCellStr(indexCellStrCpt, :) = [prof.loopNumber {indexStr}];
      indexCellStrCpt = indexCellStrCpt + 1;
   end
end

g_cogeoab_profTab(1:g_cogeoab_profTabId-1) = [];
g_cogeoab_profTabId = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGC CSV index files

for loopNumber = 1:6 % one loop for each BGC dataset + the concatenated one
   idForLoop = find([indexCellStr{1:indexCellStrCpt-1, 1}] == loopNumber);
   if (~isempty(idForLoop))

      switch (loopNumber)
         case 1
            indexFileHeaderFormat = 'EasyOneArgoDOXYIndexList';
            indexFilePathName = g_cogeoab_indexFileDoxy;
            g_cogeoab_nbOutputFilesDoxy = g_cogeoab_nbOutputFilesDoxy + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,oxygen';
         case 2
            indexFileHeaderFormat = 'EasyOneArgoNITRATEIndexList';
            indexFilePathName = g_cogeoab_indexFileNitrate;
            g_cogeoab_nbOutputFilesNitrate = g_cogeoab_nbOutputFilesNitrate + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,nitrate';
         case 3
            indexFileHeaderFormat = 'EasyOneArgoPHIndexList';
            indexFilePathName = g_cogeoab_indexFilePh;
            g_cogeoab_nbOutputFilesPh = g_cogeoab_nbOutputFilesPh + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,pH';
         case 4
            indexFileHeaderFormat = 'EasyOneArgoCHLA_BBPIndexList';
            indexFilePathName = g_cogeoab_indexFileChlaBbp;
            g_cogeoab_nbOutputFilesChlaBbp = g_cogeoab_nbOutputFilesChlaBbp + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,chla,chlaFluorescence,bbp700';
         case 5
            indexFileHeaderFormat = 'EasyOneArgoRADIOMETRYIndexList';
            indexFilePathName = g_cogeoab_indexFileRadiometry;
            g_cogeoab_nbOutputFilesRadiometry = g_cogeoab_nbOutputFilesRadiometry + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,downIrr380,downIrr412,downIrr443,downIrr490,downIrr555,downwellingPar';
         case 6
            indexFileHeaderFormat = 'EasyOneArgoBGCIndexList';
            indexFilePathName = g_cogeoab_indexFileBgc;
            g_cogeoab_nbOutputFilesBgc = g_cogeoab_nbOutputFilesBgc + length(idForLoop);
            paramListStr = 'pressure,temperature,salinity,oxygen,nitrate,pH,chla,chlaFluorescence,bbp700,downIrr380,downIrr412,downIrr443,downIrr490,downIrr555,downwellingPar';
      end

      if ~(exist(indexFilePathName, 'file') == 2)

         header = cell(7, 1);
         header{1} = ['#format = ' indexFileHeaderFormat];
         header{2} = ['#creation_date = ' g_cogeoab_nowUtcStr];
         header{3} = '#creation_centre = Ifremer';
         header{4} = '#creation_centre_pid = https://ror.org/044jxhp58';
         header{5} = ['#creation_tool_version = ' g_cogeoab_generateEasyOneArgoBgcVersion];
         header{6} = ['#data_mode is provided for all parameters listed in the following order: ' paramListStr];
         header{7} = 'data_centre,platform_number,cycle_number,direction_of_profile,data_mode,profile_date,profile_latitude,profile_longitude,maximum_pressure_of_good_data';

         fId = fopen(indexFilePathName, 'wt');
         if (fId == -1)
            fprintf('ERROR: Error while creating file : %s\n', indexFilePathName);
            return
         end
         fprintf(fId, '%s\n', header{:});
         fclose(fId);
      end

      fId = fopen(indexFilePathName, 'at');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', indexFilePathName);
         return
      end
      fprintf(fId, '%s\n', indexCellStr{idForLoop, 2});
      fclose(fId);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGCLite CSV data files

indexCellStr = cell(g_cogeoab_profLiteTabId-1, 1);
indexCellStrCpt = 1;
matOutputData = repmat(get_mat_prof_data_init_struct, 1, g_cogeoab_profLiteTabId-1);
matOutputDataCpt = 1;
for idProf = 1:g_cogeoab_profLiteTabId-1
   prof = g_cogeoab_profLiteTab(idProf);

   if ((sum(prof.dataGridParamId(1:3)) == 3) && (sum(prof.dataGridParamId) > 3))

      header = cell(29, 1);
      header{1} = '#format = EasyOneArgoBGCLite';
      header{2} = ['#creation_date = ' g_cogeoab_nowUtcStr];
      header{3} = '#creation_centre = Ifremer';
      header{4} = '#creation_centre_pid = https://ror.org/044jxhp58';
      header{5} = ['#data_source_doi = ' g_cogeoab_inputDataDoi];
      header{6} = ['#data_centre = ' get_extended_data_center(prof.dac)];
      header{7} = ['#platform_number = ' prof.wmo];
      header{8} = ['#cycle_number = ' prof.cyNumStr];
      header{9} = ['#direction_of_profile (''A'' : ascending, ''D'' : descending) = ' prof.dir];      
      header{10} = ['#parameter_data_mode (listed in order of the parameters in the header, ''D'' : delayed-mode, ''A'' : adjusted in real-time, ''-'' : parameter not available) = ' prof.paramDataModeAll];
      header{11} = ['#profile_date = ' prof.juldStr];
      header{12} = ['#profile_latitude = ' prof.latStr];
      header{13} = ['#profile_longitude = ' prof.lonStr];
      header{14} = '#pressure = sea water pressure equals 0 at sea-level';
      header{15} = '#temperature = sea temperature in-situ ITS-90 scale';
      header{16} = '#salinity = practical salinity';
      header{17} = '#oxygen = dissolved oxygen';
      header{18} = '#nitrate = nitrate';
      header{19} = '#pH = seawater pH reported on total scale';
      header{20} = '#chla = chlorophyll-A';
      header{21} = '#chlaFluorescence = chlorophyll-A fluorescence with factory calibration';
      header{22} = '#bbp700 = particle backscattering at 700 nanometers';
      header{23} = '#downIrr380 = downwelling irradiance at 380 nanometers';
      header{24} = '#downIrr412 = downwelling irradiance at 412 nanometers';
      header{25} = '#downIrr443 = downwelling irradiance at 443 nanometers';
      header{26} = '#downIrr490 = downwelling irradiance at 490 nanometers';
      header{27} = '#downIrr555 = downwelling irradiance at 555 nanometers';
      header{28} = '#downwellingPar = downwelling photosynthetic available radiation';
      header{29} = [ ...
         'pressure (decibar),temperature (degree_celsius),salinity (dimensionless),' ...
         'oxygen (micromole/kg),'...
         'nitrate (micromole/kg),' ...
         'pH (dimensionless),' ...
         'chla (mg/m3),chlaFluorescence (ru),bbp700 (m-1),'...
         'downIrr380 (W/m^2/nm),downIrr412 (W/m^2/nm),downIrr443 (W/m^2/nm),downIrr490 (W/m^2/nm),downIrr555 (W/m^2/nm),downwellingPar (microMoleQuanta/m^2/sec),' ...
         'pressure_error (decibar),temperature_error (degree_celsius),salinity_error (dimensionless),' ...
         'oxygen_error (micromole/kg),'...
         'nitrate_error (micromole/kg),' ...
         'pH_error (dimensionless),' ...
         'chla_error (mg/m3),chlaFluorescence_error (ru),bbp700_error (m-1),' ...
         'downIrr380_error (W/m^2/nm),downIrr412_error (W/m^2/nm),downIrr443_error (W/m^2/nm),downIrr490_error (W/m^2/nm),downIrr555_error (W/m^2/nm),downwellingPar_error (microMoleQuanta/m^2/sec)'];

      % some BGC parameters may be missing
      dataStr = cell(size(prof.dataGrid, 1), 1);
      fmtParam = [ ...
         {'%.2f'} {',%.3f'} {',%.3f'} ...
         {',%.3f'} ...
         {',%.3f'} ...
         {',%.4f'} ...
         {',%.4f'} {',%.4f'} {',%.7f'} ...
         {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} ...
         {',%.2f'} {',%.3f'} {',%.3f'} ...
         {',%.3f'} ...
         {',%.3f'} ...
         {',%.4f'} ...
         {',%.4f'} {',%.4f'} {',%.7f'} ...
         {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'} {',%.3f'}];
      data = [prof.dataGrid, prof.dataGridErr];
      fmtData = repmat(fmtParam, size(data, 1), 1);
      fmtData(isnan(data)) = {','};
      for idL = 1:size(data, 1)
         dataL = data(idL, :);
         dataL(isnan(dataL)) = [];
         dataStr{idL} = sprintf([fmtData{idL, :}], dataL);
      end

      % create the float directory
      dirOutputCsvFloatName = [g_cogeoab_dirOutputCsvFileBgcLiteData '/' prof.wmo];
      if ~(exist(dirOutputCsvFloatName, 'dir') == 7)
         mkdir(dirOutputCsvFloatName);
      end

      % create output CSV file
      if (prof.dir == 'A')
         profDirStr = '';
      else
         profDirStr = 'D';
      end
      csvFileBaseName = sprintf('%s_%03d%c_', prof.wmo, prof.cyNum, profDirStr);
      csvFilepathName = [dirOutputCsvFloatName '/' csvFileBaseName 'EasyBGCLite.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
         return
      end

      fprintf(fId, '%s\n', header{:});
      fprintf(fId, '%s\n', dataStr{:});

      fclose(fId);

      % store index data
      indexStr = sprintf('%s,%s,%s,%c,%s,%s,%s,%s,%.2f', ...
         prof.dac, ...
         prof.wmo, ...
         prof.cyNumStr, ...
         prof.dir, ...
         prof.paramDataModeAll, ...
         prof.juldStr, ...
         prof.latStr, ...
         prof.lonStr, ...
         prof.dataGridMaxPres);
      indexCellStr(indexCellStrCpt) = {indexStr};
      indexCellStrCpt = indexCellStrCpt + 1;
   end

   % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store MAT output data
   if (~isempty(prof.dataMat))
      matOutputData(matOutputDataCpt) = prof.dataMat;
      matOutputDataCpt = matOutputDataCpt + 1;
   end
end

g_cogeoab_profLiteTab(1:g_cogeoab_profLiteTabId-1) = [];
g_cogeoab_profLiteTabId = 1;
matOutputData(matOutputDataCpt:end) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create output EasyOneArgoBGCLite CSV index file

if ~(exist(g_cogeoab_indexFileBgcLite, 'file') == 2)

   header = cell(7, 1);
   header{1} = '#format = EasyOneArgoBGCLiteIndexList';
   header{2} = ['#creation_date = ' g_cogeoab_nowUtcStr];
   header{3} = '#creation_centre = Ifremer';
   header{4} = '#creation_centre_pid = https://ror.org/044jxhp58';
   header{5} = ['#creation_tool_version = ' g_cogeoab_generateEasyOneArgoBgcVersion];
   header{6} = '#data_mode is provided for all parameters listed in the following order: pressure,temperature,salinity,oxygen,nitrate,pH,chla,chlaFluorescence,bbp700,downIrr380,downIrr412,downIrr443,downIrr490,downIrr555,downwellingPar';
   header{7} = 'data_centre,platform_number,cycle_number,direction_of_profile,data_mode,profile_date,profile_latitude,profile_longitude,maximum_pressure_of_good_data';

   fId = fopen(g_cogeoab_indexFileBgcLite, 'wt');
   if (fId == -1)
      fprintf('ERROR: Error while creating file : %s\n', g_cogeoab_indexFileBgcLite);
      return
   end
   fprintf(fId, '%s\n', header{:});
   fclose(fId);
end

fId = fopen(g_cogeoab_indexFileBgcLite, 'at');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', g_cogeoab_indexFileBgcLite);
   return
end
fprintf(fId, '%s\n', indexCellStr{1:indexCellStrCpt-1});
fclose(fId);

g_cogeoab_nbOutputFilesBgcLite = g_cogeoab_nbOutputFilesBgcLite + indexCellStrCpt - 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create temporary output MAT files with output MAT data

if (~isempty(matOutputData))

   wmoBoxList = unique([matOutputData.wmoBox]);
   for boxNum = wmoBoxList
      idProf = find([matOutputData.wmoBox] == boxNum);

      % gather MAT data for the current WMO box
      profBox = get_mat_prof_data_init_struct;
      profBox.wmoBox = boxNum;
      profBox.nbLev = max([matOutputData(idProf).nbLev]);
      profBox.source = [matOutputData(idProf).source];
      profBox.dates = [matOutputData(idProf).dates];
      profBox.lat = [matOutputData(idProf).lat];
      profBox.long = [matOutputData(idProf).long];

      profBox.templite = [matOutputData(idProf).templite];
      profBox.sallite = [matOutputData(idProf).sallite];
      profBox.doxylite = [matOutputData(idProf).doxylite];
      profBox.nitratelite = [matOutputData(idProf).nitratelite];
      profBox.phinsitutotallite = [matOutputData(idProf).phinsitutotallite];
      profBox.chlalite = [matOutputData(idProf).chlalite];
      profBox.chlafluorescencelite = [matOutputData(idProf).chlafluorescencelite];
      profBox.bbp700lite = [matOutputData(idProf).bbp700lite];
      profBox.downirradiance380lite = [matOutputData(idProf).downirradiance380lite];
      profBox.downirradiance412lite = [matOutputData(idProf).downirradiance412lite];
      profBox.downirradiance443lite = [matOutputData(idProf).downirradiance443lite];
      profBox.downirradiance490lite = [matOutputData(idProf).downirradiance490lite];
      profBox.downirradiance555lite = [matOutputData(idProf).downirradiance555lite];
      profBox.downwellingparlite = [matOutputData(idProf).downwellingparlite];

      profBox.preso = nan(profBox.nbLev, length(idProf));
      profBox.presadj = nan(profBox.nbLev, length(idProf));
      profBox.presadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.tempo = nan(profBox.nbLev, length(idProf));
      profBox.tempadj = nan(profBox.nbLev, length(idProf));
      profBox.tempadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.salo = nan(profBox.nbLev, length(idProf));
      profBox.saladj = nan(profBox.nbLev, length(idProf));
      profBox.saladjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.doxyo = nan(profBox.nbLev, length(idProf));
      profBox.doxyadj = nan(profBox.nbLev, length(idProf));
      profBox.doxyadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.nitrateo = nan(profBox.nbLev, length(idProf));
      profBox.nitrateadj = nan(profBox.nbLev, length(idProf));
      profBox.nitrateadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.phinsitutotalo = nan(profBox.nbLev, length(idProf));
      profBox.phinsitutotaladj = nan(profBox.nbLev, length(idProf));
      profBox.phinsitutotaladjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.chlao = nan(profBox.nbLev, length(idProf));
      profBox.chlaadj = nan(profBox.nbLev, length(idProf));
      profBox.chlaadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.chlafluorescenceo = nan(profBox.nbLev, length(idProf));
      profBox.chlafluorescenceadj = nan(profBox.nbLev, length(idProf));
      profBox.chlafluorescenceadjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.bbp700o = nan(profBox.nbLev, length(idProf));
      profBox.bbp700adj = nan(profBox.nbLev, length(idProf));
      profBox.bbp700adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance380o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance380adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance380adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance412o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance412adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance412adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance443o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance443adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance443adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance490o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance490adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance490adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downirradiance555o = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance555adj = nan(profBox.nbLev, length(idProf));
      profBox.downirradiance555adjqc = repmat(' ', profBox.nbLev, length(idProf));

      profBox.downwellingparo = nan(profBox.nbLev, length(idProf));
      profBox.downwellingparadj = nan(profBox.nbLev, length(idProf));
      profBox.downwellingparadjqc = repmat(' ', profBox.nbLev, length(idProf));

      for idP = 1:length(idProf)
         profBox.preso(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).preso;
         profBox.presadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).presadj;
         profBox.presadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).presadjqc);

         profBox.tempo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).tempo;
         profBox.tempadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).tempadj;
         profBox.tempadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).tempadjqc);

         profBox.salo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).salo;
         profBox.saladj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).saladj;
         profBox.saladjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).saladjqc);

         profBox.doxyo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).doxyo;
         profBox.doxyadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).doxyadj;
         profBox.doxyadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).doxyadjqc);

         profBox.nitrateo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).nitrateo;
         profBox.nitrateadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).nitrateadj;
         profBox.nitrateadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).nitrateadjqc);

         profBox.phinsitutotalo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).phinsitutotalo;
         profBox.phinsitutotaladj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).phinsitutotaladj;
         profBox.phinsitutotaladjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).phinsitutotaladjqc);

         profBox.chlao(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlao;
         profBox.chlaadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlaadj;
         profBox.chlaadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).chlaadjqc);

         profBox.chlafluorescenceo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlafluorescenceo;
         profBox.chlafluorescenceadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).chlafluorescenceadj;
         profBox.chlafluorescenceadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).chlafluorescenceadjqc);

         profBox.bbp700o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).bbp700o;
         profBox.bbp700adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).bbp700adj;
         profBox.bbp700adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).bbp700adjqc);

         profBox.downirradiance380o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance380o;
         profBox.downirradiance380adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance380adj;
         profBox.downirradiance380adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance380adjqc);

         profBox.downirradiance412o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance412o;
         profBox.downirradiance412adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance412adj;
         profBox.downirradiance412adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance412adjqc);

         profBox.downirradiance443o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance443o;
         profBox.downirradiance443adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance443adj;
         profBox.downirradiance443adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance443adjqc);

         profBox.downirradiance490o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance490o;
         profBox.downirradiance490adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance490adj;
         profBox.downirradiance490adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance490adjqc);

         profBox.downirradiance555o(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance555o;
         profBox.downirradiance555adj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downirradiance555adj;
         profBox.downirradiance555adjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downirradiance555adjqc);

         profBox.downwellingparo(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downwellingparo;
         profBox.downwellingparadj(1:matOutputData(idProf(idP)).nbLev, idP) = matOutputData(idProf(idP)).downwellingparadj;
         profBox.downwellingparadjqc(1:matOutputData(idProf(idP)).nbLev, idP) = num2str(matOutputData(idProf(idP)).downwellingparadjqc);
      end

      % create output MAT file
      matFileName = sprintf('%d_%d_%d_%d_tempo.mat', ...
         boxNum, profBox.nbLev, size(profBox.preso, 2), g_cogeoab_tempoOutPutMatId);
      matFilePathName = [g_cogeoab_dirOutputMatFile '/' matFileName];
      save(matFilePathName, '-struct', 'profBox');
      g_cogeoab_tempoOutPutMatId = g_cogeoab_tempoOutPutMatId + 1;
   end
end

return

% ------------------------------------------------------------------------------
% Concatenate output MAT files.
%
% SYNTAX :
%    concat_output_mat_files
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function concat_output_mat_files

% input parameters
global g_cogeoab_generateOutputAuditFlag;
global g_cogeoab_dirOutputMatFile;

% defined levels of vertical interpolation grid
global g_cogeoab_eoaLevels;

% number of output files generated
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMat;

if (~g_cogeoab_generateOutputAuditFlag)
   return
end

% look for temporary output MAT files and retrieve information from their names
tempMatFileNames = dir([g_cogeoab_dirOutputMatFile '/*_tempo.mat']);
fileNameList = cell(1, length(tempMatFileNames));
wmoBoxList = nan(1, length(tempMatFileNames));
nbLevList = ones(1, length(tempMatFileNames))*-1;
nbProfList = zeros(1, length(tempMatFileNames));
nbFileIdList = nan(1, length(tempMatFileNames));
for idFile = 1:length(tempMatFileNames)
   fileName = tempMatFileNames(idFile).name;
   idFus = strfind(fileName, '_');
   fileNameList{idFile} = fileName;
   wmoBoxList(idFile) = str2double(fileName(1:idFus(1)-1));
   nbLevList(idFile) = str2double(fileName(idFus(1)+1:idFus(2)-1));
   nbProfList(idFile) = str2double(fileName(idFus(2)+1:idFus(3)-1));
   nbFileIdList(idFile) = str2double(fileName(idFus(3)+1:idFus(4)-1));
end

wmoBox = unique(wmoBoxList);
for boxNum = wmoBox
   idProf = find(wmoBoxList == boxNum);

   nbLev = max(nbLevList(idProf));
   nbProf = sum(nbProfList(idProf));
   % sort profiles so that they appear in each WMO box in the same order as in
   % the index file
   nbFileIdAll = [nbFileIdList(idProf)];
   [~, idSort] = sort(nbFileIdAll);
   idProf = idProf(idSort);

   % gather MAT data for the current WMO box
   profBox = get_mat_prof_data_init_struct;
   profBox.source =  cell(1, nbProf);
   profBox.dates = cell(1, nbProf);
   profBox.lat = nan(1, nbProf);
   profBox.long = nan(1, nbProf);

   profBox.preslitelevels = g_cogeoab_eoaLevels;
   profBox.templite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.sallite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.doxylite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.nitratelite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.phinsitutotallite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.chlalite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.chlafluorescencelite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.bbp700lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downirradiance380lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downirradiance412lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downirradiance443lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downirradiance490lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downirradiance555lite = nan(length(g_cogeoab_eoaLevels), nbProf);
   profBox.downwellingparlite = nan(length(g_cogeoab_eoaLevels), nbProf);

   profBox.preso = nan(nbLev, nbProf);
   profBox.presadj = nan(nbLev, nbProf);
   profBox.presadjqc = repmat(' ', nbLev, nbProf);

   profBox.tempo = nan(nbLev, nbProf);
   profBox.tempadj = nan(nbLev, nbProf);
   profBox.tempadjqc = repmat(' ', nbLev, nbProf);

   profBox.salo = nan(nbLev, nbProf);
   profBox.saladj = nan(nbLev, nbProf);
   profBox.saladjqc = repmat(' ', nbLev, nbProf);

   profBox.doxyo = nan(nbLev, nbProf);
   profBox.doxyadj = nan(nbLev, nbProf);
   profBox.doxyadjqc = repmat(' ', nbLev, nbProf);

   profBox.nitrateo = nan(nbLev, nbProf);
   profBox.nitrateadj = nan(nbLev, nbProf);
   profBox.nitrateadjqc = repmat(' ', nbLev, nbProf);

   profBox.phinsitutotalo = nan(nbLev, nbProf);
   profBox.phinsitutotaladj = nan(nbLev, nbProf);
   profBox.phinsitutotaladjqc = repmat(' ', nbLev, nbProf);

   profBox.chlao = nan(nbLev, nbProf);
   profBox.chlaadj = nan(nbLev, nbProf);
   profBox.chlaadjqc = repmat(' ', nbLev, nbProf);

   profBox.chlafluorescenceo = nan(nbLev, nbProf);
   profBox.chlafluorescenceadj = nan(nbLev, nbProf);
   profBox.chlafluorescenceadjqc = repmat(' ', nbLev, nbProf);

   profBox.bbp700o = nan(nbLev, nbProf);
   profBox.bbp700adj = nan(nbLev, nbProf);
   profBox.bbp700adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance380o = nan(nbLev, nbProf);
   profBox.downirradiance380adj = nan(nbLev, nbProf);
   profBox.downirradiance380adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance412o = nan(nbLev, nbProf);
   profBox.downirradiance412adj = nan(nbLev, nbProf);
   profBox.downirradiance412adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance443o = nan(nbLev, nbProf);
   profBox.downirradiance443adj = nan(nbLev, nbProf);
   profBox.downirradiance443adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance490o = nan(nbLev, nbProf);
   profBox.downirradiance490adj = nan(nbLev, nbProf);
   profBox.downirradiance490adjqc = repmat(' ', nbLev, nbProf);

   profBox.downirradiance555o = nan(nbLev, nbProf);
   profBox.downirradiance555adj = nan(nbLev, nbProf);
   profBox.downirradiance555adjqc = repmat(' ', nbLev, nbProf);

   profBox.downwellingparo = nan(nbLev, nbProf);
   profBox.downwellingparadj = nan(nbLev, nbProf);
   profBox.downwellingparadjqc = repmat(' ', nbLev, nbProf);

   fistId = 1;
   for idP = 1:length(idProf)

      tempMatFileName = [g_cogeoab_dirOutputMatFile '/' fileNameList{idProf(idP)}];
      profBoxIn = load(tempMatFileName);

      lastId = fistId + nbProfList(idProf(idP)) - 1;

      profBox.source(fistId:lastId) = profBoxIn.source;
      profBox.dates(fistId:lastId) = profBoxIn.dates;
      profBox.lat(fistId:lastId) = profBoxIn.lat;
      profBox.long(fistId:lastId) = profBoxIn.long;

      profBox.templite(:, fistId:lastId) = profBoxIn.templite;
      profBox.sallite(:, fistId:lastId) = profBoxIn.sallite;
      profBox.doxylite(:, fistId:lastId) = profBoxIn.doxylite;
      profBox.nitratelite(:, fistId:lastId) = profBoxIn.nitratelite;
      profBox.phinsitutotallite(:, fistId:lastId) = profBoxIn.phinsitutotallite;
      profBox.chlalite(:, fistId:lastId) = profBoxIn.chlalite;
      profBox.chlafluorescencelite(:, fistId:lastId) = profBoxIn.chlafluorescencelite;
      profBox.bbp700lite(:, fistId:lastId) = profBoxIn.bbp700lite;
      profBox.downirradiance380lite(:, fistId:lastId) = profBoxIn.downirradiance380lite;
      profBox.downirradiance412lite(:, fistId:lastId) = profBoxIn.downirradiance412lite;
      profBox.downirradiance443lite(:, fistId:lastId) = profBoxIn.downirradiance443lite;
      profBox.downirradiance490lite(:, fistId:lastId) = profBoxIn.downirradiance490lite;
      profBox.downirradiance555lite(:, fistId:lastId) = profBoxIn.downirradiance555lite;
      profBox.downwellingparlite(:, fistId:lastId) = profBoxIn.downwellingparlite;

      profBox.preso(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.preso;
      profBox.presadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadj;
      profBox.presadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.presadjqc;

      profBox.tempo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempo;
      profBox.tempadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadj;
      profBox.tempadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.tempadjqc;

      profBox.salo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.salo;
      profBox.saladj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladj;
      profBox.saladjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.saladjqc;

      profBox.doxyo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyo;
      profBox.doxyadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyadj;
      profBox.doxyadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.doxyadjqc;

      profBox.nitrateo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateo;
      profBox.nitrateadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateadj;
      profBox.nitrateadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.nitrateadjqc;

      profBox.phinsitutotalo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotalo;
      profBox.phinsitutotaladj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotaladj;
      profBox.phinsitutotaladjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.phinsitutotaladjqc;

      profBox.chlao(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlao;
      profBox.chlaadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlaadj;
      profBox.chlaadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlaadjqc;

      profBox.chlafluorescenceo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlafluorescenceo;
      profBox.chlafluorescenceadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlafluorescenceadj;
      profBox.chlafluorescenceadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.chlafluorescenceadjqc;

      profBox.bbp700o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700o;
      profBox.bbp700adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700adj;
      profBox.bbp700adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.bbp700adjqc;

      profBox.downirradiance380o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380o;
      profBox.downirradiance380adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380adj;
      profBox.downirradiance380adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance380adjqc;

      profBox.downirradiance412o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412o;
      profBox.downirradiance412adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412adj;
      profBox.downirradiance412adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance412adjqc;

      profBox.downirradiance443o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance443o;
      profBox.downirradiance443adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance443adj;
      profBox.downirradiance443adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance443adjqc;

      profBox.downirradiance490o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490o;
      profBox.downirradiance490adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490adj;
      profBox.downirradiance490adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance490adjqc;

      profBox.downirradiance555o(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance555o;
      profBox.downirradiance555adj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance555adj;
      profBox.downirradiance555adjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downirradiance555adjqc;

      profBox.downwellingparo(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparo;
      profBox.downwellingparadj(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparadj;
      profBox.downwellingparadjqc(1:nbLevList(idProf(idP)), fistId:lastId) = profBoxIn.downwellingparadjqc;

      fistId = fistId + nbProfList(idProf(idP));

      % remove current temporary output MAT file
      delete(tempMatFileName);
   end

   % create output MAT file
   matFileName = sprintf('audit_%d.mat', boxNum);
   matFilePathName = [g_cogeoab_dirOutputMatFile '/' matFileName];
   save(matFilePathName, '-struct', 'profBox', ...
      'source', 'dates', 'lat', 'long', ...
      'preslitelevels', 'templite', 'sallite', ...
      'doxylite', 'nitratelite', 'phinsitutotallite', ...
      'chlalite', 'chlafluorescencelite', 'bbp700lite', ...
      'downirradiance380lite', 'downirradiance412lite', ...
      'downirradiance443lite', 'downirradiance490lite', ...
      'downirradiance555lite', 'downwellingparlite', ...
      'preso', 'presadj', 'presadjqc', ...
      'tempo', 'tempadj', 'tempadjqc', ...
      'salo', 'saladj', 'saladjqc', ...
      'doxyo', 'doxyadj', 'doxyadjqc', ...
      'nitrateo', 'nitrateadj', 'nitrateadjqc', ...
      'phinsitutotalo', 'phinsitutotaladj', 'phinsitutotaladjqc', ...
      'chlao', 'chlaadj', 'chlaadjqc', ...
      'chlafluorescenceo', 'chlafluorescenceadj', 'chlafluorescenceadjqc', ...
      'bbp700o', 'bbp700adj', 'bbp700adjqc', ...
      'downirradiance380o', 'downirradiance380adj', 'downirradiance380adjqc', ...
      'downirradiance412o', 'downirradiance412adj', 'downirradiance412adjqc', ...
      'downirradiance443o', 'downirradiance443adj', 'downirradiance443adjqc', ...
      'downirradiance490o', 'downirradiance490adj', 'downirradiance490adjqc', ...
      'downirradiance555o', 'downirradiance555adj', 'downirradiance555adjqc', ...
      'downwellingparo', 'downwellingparadj', 'downwellingparadjqc');

   g_cogeoab_nbOutputProfMat = g_cogeoab_nbOutputProfMat + nbProf;
   g_cogeoab_nbOutputFilesMat = g_cogeoab_nbOutputFilesMat + 1;
end

return

% ------------------------------------------------------------------------------
% Function to convert position to WMO box number.
% number is nan if lat < -90 or lat >= 90
%
% SYNTAX :
%  [o_wmoNumber] = pos_to_wmo(a_long, a_lat)
%
% INPUT PARAMETERS :
%   a_long : position longitude ([0,360[ or [-180,180[)
%   a_lat  : position latitude ([-90,90[,)
%
% OUTPUT PARAMETERS :
%   o_wmoNumber : box WMO number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/29/2025 - RNU - creation (from BAK 16 March 2004, based on earlier code by HRL)
% ------------------------------------------------------------------------------
function [o_wmoNumber] = pos_to_wmo(a_long, a_lat)

% output parameters initialization
o_wmoNumber = nan;

w = nan;
x = nan;
yz = nan;
LAT = a_lat;
LONG = mod(a_long, 360); %LONG is in range [0,360[

if     (LAT >= 0 &   0 <= LONG & LONG < 180) w = 1;
elseif (LAT >= 0 & 180 <= LONG & LONG < 360) w = 7;
elseif (LAT <  0 &   0 <= LONG & LONG < 180) w = 3;
elseif (LAT <  0 & 180 <= LONG & LONG < 360) w = 5;
end

%if         (( 0 <= LAT & LAT < 10) | (-10 <= LAT & LAT <   0)) x = 0;
%    elseif ((10 <= LAT & LAT < 20) | (-20 <= LAT & LAT < -10)) x = 1;
%    elseif ((20 <= LAT & LAT < 30) | (-30 <= LAT & LAT < -20)) x = 2;
%    elseif ((30 <= LAT & LAT < 40) | (-40 <= LAT & LAT < -30)) x = 3;
%    elseif ((40 <= LAT & LAT < 50) | (-50 <= LAT & LAT < -40)) x = 4;
%    elseif ((50 <= LAT & LAT < 60) | (-60 <= LAT & LAT < -50)) x = 5;
%    elseif ((60 <= LAT & LAT < 70) | (-70 <= LAT & LAT < -60)) x = 6;
%    elseif ((70 <= LAT & LAT < 80) | (-80 <= LAT & LAT < -70)) x = 7;
%    elseif ((80 <= LAT & LAT < 90) | (-90 <= LAT & LAT < -80)) x = 8;
%end

% the table above can be reduced to the following
if (LAT >= 0)
   x = floor(LAT/10);
else
   x = ceil(-LAT/10)-1;
end
if (x > 8)
   x = nan;
end

%if         ((  0 <= LONG & LONG <  10) | (350 <= LONG & LONG < 360)) y = 0;  z = 0;
%    elseif (( 10 <= LONG & LONG <  20) | (340 <= LONG & LONG < 350)) y = 0;  z = 1;
%    elseif (( 20 <= LONG & LONG <  30) | (330 <= LONG & LONG < 340)) y = 0;  z = 2;
%    elseif (( 30 <= LONG & LONG <  40) | (320 <= LONG & LONG < 330)) y = 0;  z = 3;
%    elseif (( 40 <= LONG & LONG <  50) | (310 <= LONG & LONG < 320)) y = 0;  z = 4;
%    elseif (( 50 <= LONG & LONG <  60) | (300 <= LONG & LONG < 310)) y = 0;  z = 5;
%    elseif (( 60 <= LONG & LONG <  70) | (290 <= LONG & LONG < 300)) y = 0;  z = 6;
%    elseif (( 70 <= LONG & LONG <  80) | (280 <= LONG & LONG < 290)) y = 0;  z = 7;
%    elseif (( 80 <= LONG & LONG <  90) | (270 <= LONG & LONG < 280)) y = 0;  z = 8;
%    elseif (( 90 <= LONG & LONG < 100) | (260 <= LONG & LONG < 270)) y = 0;  z = 9;
%    elseif ((100 <= LONG & LONG < 110) | (250 <= LONG & LONG < 260)) y = 1;  z = 0;
%    elseif ((110 <= LONG & LONG < 120) | (240 <= LONG & LONG < 250)) y = 1;  z = 1;
%    elseif ((120 <= LONG & LONG < 130) | (230 <= LONG & LONG < 240)) y = 1;  z = 2;
%    elseif ((130 <= LONG & LONG < 140) | (220 <= LONG & LONG < 230)) y = 1;  z = 3;
%    elseif ((140 <= LONG & LONG < 150) | (210 <= LONG & LONG < 220)) y = 1;  z = 4;
%    elseif ((150 <= LONG & LONG < 160) | (200 <= LONG & LONG < 210)) y = 1;  z = 5;
%    elseif ((160 <= LONG & LONG < 170) | (190 <= LONG & LONG < 200)) y = 1;  z = 6;
%    elseif ((170 <= LONG & LONG < 180) | (180 <= LONG & LONG < 190)) y = 1;  z = 7;
%end

% the table above can be reduced to the following
if (LONG >= 180)
   LONG = LONG-360;
end  %LONG is now in range [-180,180[
if(LONG >= 0)
   yz = floor(LONG/10);
else
   yz = ceil(-LONG/10)-1;
end

% o_wmoNumber = (w*1000 + x*100 + y*10 + z);
o_wmoNumber = (w*1000 + x*100 + yz);

return

% ------------------------------------------------------------------------------
% Load interpolation reference levels.
%
% SYNTAX :
%  load_eoa_levels_ref
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function load_eoa_levels_ref

% defined levels of vertical interpolation grid
global g_cogeoab_eoaLevels;
global g_cogeoab_eoaUBoundLevel;
global g_cogeoab_eoaLBoundLevel;

levels = [2 5:5:250, 260:10:350, 375:25:500, 550:50:1000, 1100:100:2000, ...
   2200:200:6000]';

g_cogeoab_eoaLevels = levels;
g_cogeoab_eoaUBoundLevel = 0.5; % upper boundary of the first (shallowest) box
g_cogeoab_eoaLBoundLevel = 6100; % lower boundary of the last (deepest) box

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store profile information.
%
% SYNTAX :
%  [o_profDataStruct] = get_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profDataStruct : profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_prof_data_init_struct

% output parameters initialization
o_profDataStruct = struct( ...
   'loopNumber', '', ...
   'wmo', '', ...
   'dac', '', ...
   'cyNum', '', ...
   'cyNumStr', '', ...
   'dir', '', ...
   'parameterList', [], ...
   'paramDataMode', [], ...
   'paramDataModeAll', [], ...
   'juld', '', ...
   'juldStr', '', ...
   'lat', '', ...
   'latStr', '', ...
   'lon', '', ...
   'lonStr', '', ...
   'data', [], ...
   'dataMaxPres', '', ...
   'dataErr', [], ...
   'rawDataParamId', [], ...
   'rawData', [], ...
   'rawDataErr', [], ...
   'dataGridParamId', [], ...
   'dataGrid', [], ...
   'dataGridMaxPres', '', ...
   'dataGridErr', [], ...
   'dataMat', []);

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store profile information for MAT output.
%
% SYNTAX :
%  [o_matProfDataStruct] = get_mat_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_matProfDataStruct : profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_matProfDataStruct] = get_mat_prof_data_init_struct

% output parameters initialization
o_matProfDataStruct = struct( ...
   'wmoBox', '', ...
   'nbLev', '', ...
   'source', '', ...
   'dates', '', ...
   'lat', '', ...
   'long', '', ...
   'preso', [], ...
   'presadj', [], ...
   'presadjqc', [], ...
   'preslitelevels', [], ...
   'tempo', [], ...
   'tempadj', [], ...
   'tempadjqc', [], ...
   'templite', [], ...
   'salo', [], ...
   'saladj', [], ...
   'saladjqc', [], ...
   'sallite', [], ...
   'doxyo', [], ...
   'doxyadj', [], ...
   'doxyadjqc', [], ...
   'doxylite', [], ...
   'nitrateo', [], ...
   'nitrateadj', [], ...
   'nitrateadjqc', [], ...
   'nitratelite', [], ...
   'phinsitutotalo', [], ...
   'phinsitutotaladj', [], ...
   'phinsitutotaladjqc', [], ...
   'phinsitutotallite', [], ...
   'chlao', [], ...
   'chlaadj', [], ...
   'chlaadjqc', [], ...
   'chlalite', [], ...
   'chlafluorescenceo', [], ...
   'chlafluorescenceadj', [], ...
   'chlafluorescenceadjqc', [], ...
   'chlafluorescencelite', [], ...
   'bbp700o', [], ...
   'bbp700adj', [], ...
   'bbp700adjqc', [], ...
   'bbp700lite', [], ...
   'downirradiance380o', [], ...
   'downirradiance380adj', [], ...
   'downirradiance380adjqc', [], ...
   'downirradiance380lite', [], ...
   'downirradiance412o', [], ...
   'downirradiance412adj', [], ...
   'downirradiance412adjqc', [], ...
   'downirradiance412lite', [], ...
   'downirradiance443o', [], ...
   'downirradiance443adj', [], ...
   'downirradiance443adjqc', [], ...
   'downirradiance443lite', [], ...
   'downirradiance490o', [], ...
   'downirradiance490adj', [], ...
   'downirradiance490adjqc', [], ...
   'downirradiance490lite', [], ...
   'downirradiance555o', [], ...
   'downirradiance555adj', [], ...
   'downirradiance555adjqc', [], ...
   'downirradiance555lite', [], ...
   'downwellingparo', [], ...
   'downwellingparadj', [], ...
   'downwellingparadjqc', [], ...
   'downwellingparlite', []);

return

% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

import matlab.io.xml.dom.*

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;


% initialize XML report
docNode = Document('coriolis_function_report');
docRootNode = getDocumentElement(docNode);

newChild = createElement(docNode, 'function');
textNode = 'CO-05-08-16-02';
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'comment');
textNode = 'Argo Coriolis Easy OneArgo BGC generator (generate_easy_one_argo_bgc)';
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'tool_version');
textNode = g_cogeoab_generateEasyOneArgoBgcVersion;
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'date');
textNode = datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS');
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

g_cogeoab_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cogeoab_dirInputNcFiles;
global g_cogeoab_dirInputMinMaxFiles;
global g_cogeoab_inputDataDoi;
global g_cogeoab_dirOutputCsvFiles;
global g_cogeoab_dirLogFile;
global g_cogeoab_dirOutputXmlFile;
global g_cogeoab_xmlReportFileName;
global g_cogeoab_generateOutputAuditFlag;
global g_cogeoab_dirOutputAuditFiles;

g_cogeoab_dirInputNcFiles = [];
g_cogeoab_dirInputMinMaxFiles = [];
g_cogeoab_inputDataDoi = [];
g_cogeoab_dirOutputCsvFiles = [];
g_cogeoab_dirLogFile = [];
g_cogeoab_dirOutputXmlFile = [];
g_cogeoab_xmlReportFileName = [];
g_cogeoab_generateOutputAuditFlag = [];
g_cogeoab_dirOutputAuditFiles = [];


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'inputDataDir'))
            g_cogeoab_dirInputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputMinMaxDir'))
            g_cogeoab_dirInputMinMaxFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDataDoi'))
            g_cogeoab_inputDataDoi = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'csvOutputDir'))
            g_cogeoab_dirOutputCsvFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cogeoab_dirLogFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportDir'))
            g_cogeoab_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReportName'))
            g_cogeoab_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'generateOutputAuditFlag'))
            g_cogeoab_generateOutputAuditFlag = str2double(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'auditOutputDir'))
            g_cogeoab_dirOutputAuditFiles = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cogeoab_xmlReportFileName))
   if (length(g_cogeoab_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co05081602_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cogeoab_xmlReportFileName);
      g_cogeoab_xmlReportFileName = [];
   end
end

return

% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% input parameters
global g_cogeoab_generateOutputAuditFlag;

% DOM node of XML report
global g_cogeoab_xmlReportDOMNode;

% number of input files processed
global g_cogeoab_nbInputFiles;

% number of input profiles processed
global g_cogeoab_nbInputProfiles;

% number of output files generated
global g_cogeoab_nbOutputFilesBgc;
global g_cogeoab_nbOutputFilesBgcLite;
global g_cogeoab_nbOutputFilesDoxy;
global g_cogeoab_nbOutputFilesNitrate;
global g_cogeoab_nbOutputFilesPh;
global g_cogeoab_nbOutputFilesChlaBbp;
global g_cogeoab_nbOutputFilesRadiometry;
global g_cogeoab_nbOutputFilesMat;
global g_cogeoab_nbOutputProfMatExpected;
global g_cogeoab_nbOutputProfMat;

% user report files
global g_cogeoab_reportFileBgc;
global g_cogeoab_reportFileBgcLite;
global g_cogeoab_reportFileDoxy;
global g_cogeoab_reportFileNitrate;
global g_cogeoab_reportFilePh;
global g_cogeoab_reportFileChlaBbp;
global g_cogeoab_reportFileRadiometry;

% excluded profile info
global g_cogeoab_excluded_prof;

% program version
global g_cogeoab_generateEasyOneArgoBgcVersion;

% date of the run
global g_cogeoab_nowUtcStr;


% initalize final status
o_status = 'ok';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the xml report

docNode = g_cogeoab_xmlReportDOMNode;
docRootNode = getDocumentElement(docNode);

nbInputFiles = g_cogeoab_nbInputFiles;
nbInputProfiles = g_cogeoab_nbInputProfiles;
nbOutputFilesBgc = g_cogeoab_nbOutputFilesBgc;
nbOutputFilesBgcLite = g_cogeoab_nbOutputFilesBgcLite;
nbOutputFilesDoxy = g_cogeoab_nbOutputFilesDoxy;
nbOutputFilesNitrate = g_cogeoab_nbOutputFilesNitrate;
nbOutputFilesPh = g_cogeoab_nbOutputFilesPh;
nbOutputFilesChlaBbp = g_cogeoab_nbOutputFilesChlaBbp;
nbOutputFilesRadiometry = g_cogeoab_nbOutputFilesRadiometry;
nbOutputFilesMat = g_cogeoab_nbOutputFilesMat;
nbOutputProfMatExpected = g_cogeoab_nbOutputProfMatExpected;
nbOutputProfMat = g_cogeoab_nbOutputProfMat;

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

error = a_error;

duration = format_time(toc(a_ticStartTime)/3600);

newChild = createElement(docNode, 'Nb_input_nc_files');
textNode = num2str(nbInputFiles);
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'Nb_input_profiles');
textNode = num2str(nbInputProfiles);
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoBGC');
textNode = num2str(nbOutputFilesBgc);
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoBGCLite');
textNode = num2str(nbOutputFilesBgcLite);
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

if (g_cogeoab_generateOutputAuditFlag)

   newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoDOXY');
   textNode = num2str(nbOutputFilesDoxy);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoNITRATE');
   textNode = num2str(nbOutputFilesNitrate);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoPH');
   textNode = num2str(nbOutputFilesPh);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoCHLABBP');
   textNode = num2str(nbOutputFilesChlaBbp);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_csv_files_EasyOneArgoRADIOMETRY');
   textNode = num2str(nbOutputFilesRadiometry);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_mat_files_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputFilesMat);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_mat_profiles_expected_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputProfMatExpected);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);

   newChild = createElement(docNode, 'Nb_output_mat_profiles_EasyOneArgoBGCLite_audit');
   textNode = num2str(nbOutputProfMat);
   appendChild(newChild, createTextNode(docNode, textNode));
   appendChild(docRootNode, newChild);
end

if (~isempty(infoMsg))
   for idMsg = 1:length(infoMsg)
      newChild = createElement(docNode, 'info');
      textNode = infoMsg{idMsg};
      appendChild(newChild, createTextNode(docNode, textNode));
      appendChild(docRootNode, newChild);
   end
end

if (~isempty(warningMsg))
   for idMsg = 1:length(warningMsg)
      newChild = createElement(docNode, 'warning');
      textNode = warningMsg{idMsg};
      appendChild(newChild, createTextNode(docNode, textNode));
      appendChild(docRootNode, newChild);
   end
end

if (~isempty(errorMsg))
   for idMsg = 1:length(errorMsg)
      newChild = createElement(docNode, 'error');
      textNode = errorMsg{idMsg};
      appendChild(newChild, createTextNode(docNode, textNode));
      appendChild(docRootNode, newChild);
   end
   o_status = 'nok';
end

% add matlab error
if (~isempty(error))
   o_status = 'nok';

   newChild = createElement(docNode, 'matlab_error');

   for idE = 1:length(error)
      errStruct = error(idE);

      newChildBis = createElement(docNode, 'error_message');
      textNode = regexprep(errStruct.message, char(10), ': ');
      appendChild(newChildBis, createTextNode(docNode, textNode));
      appendChild(newChild, newChildBis);

      for idS = 1:size(errStruct.stack, 1)
         newChildBis = createElement(docNode, 'stack_line');
         textNode = sprintf('Line: %3d File: %s (func: %s)', ...
            errStruct.stack(idS). line, ...
            errStruct.stack(idS). file, ...
            errStruct.stack(idS). name);
         appendChild(newChildBis, createTextNode(docNode, textNode));
         appendChild(newChild, newChildBis);
      end
   end
   appendChild(docRootNode, newChild);
end

newChild = createElement(docNode, 'duration');
textNode = duration;
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

newChild = createElement(docNode, 'status');
textNode = o_status;
appendChild(newChild, createTextNode(docNode, textNode));
appendChild(docRootNode, newChild);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create user reports

% text on excluded profile information
exludedProfStr = [];

if (~g_cogeoab_generateOutputAuditFlag)
   loopNumberList = 6:7;
else
   loopNumberList = 1:7;
end
for loopNumber = loopNumberList

   switch (loopNumber)
      case 1
         nbOutputFiles = nbOutputFilesDoxy;
         datasetName = 'EasyOneArgoDOXY';
         reportFilePathName = g_cogeoab_reportFileDoxy;
      case 2
         nbOutputFiles = nbOutputFilesNitrate;
         datasetName = 'EasyOneArgoNITRATE';
         reportFilePathName = g_cogeoab_reportFileNitrate;
      case 3
         nbOutputFiles = nbOutputFilesPh;
         datasetName = 'EasyOneArgoPH';
         reportFilePathName = g_cogeoab_reportFilePh;
      case 4
         nbOutputFiles = nbOutputFilesChlaBbp;
         datasetName = 'EasyOneArgoCHLA_BBP';
         reportFilePathName = g_cogeoab_reportFileChlaBbp;
      case 5
         nbOutputFiles = nbOutputFilesRadiometry;
         datasetName = 'EasyOneArgoRADIOMETRY';
         reportFilePathName = g_cogeoab_reportFileRadiometry;
      case 6
         nbOutputFiles = nbOutputFilesBgc;
         datasetName = 'EasyOneArgoBGC';
         reportFilePathName = g_cogeoab_reportFileBgc;
      case 7
         nbOutputFiles = nbOutputFilesBgcLite;
         datasetName = 'EasyOneArgoBGCLite';
         reportFilePathName = g_cogeoab_reportFileBgcLite;
   end

   if (nbOutputFiles > 0)

      if (isempty(exludedProfStr))

         if (~isempty(g_cogeoab_excluded_prof))
            [~, idSort] = sort([g_cogeoab_excluded_prof(:, 3)]);
            g_cogeoab_excluded_prof = g_cogeoab_excluded_prof(idSort, :);
         end

         exludedProfStr{end+1} = 'List of profiles excluded from EasyOneArgo dataset (from https://data-argo.ifremer.fr/etc/Report_ObjectiveAnalysisWarning/csv_drift/)';
         exludedProfStr{end+1} = 'DAC;WMO;PI;First cycle;Last cycle';
         for idL = 1:size(g_cogeoab_excluded_prof, 1)
            exludedProfStr{end+1} = sprintf('%s;%d;%s;%d;%d', ...
               g_cogeoab_excluded_prof{idL, 3}, ...
               g_cogeoab_excluded_prof{idL, 1}, ...
               g_cogeoab_excluded_prof{idL, 4}, ...
               g_cogeoab_excluded_prof{idL, 5}, ...
               g_cogeoab_excluded_prof{idL, 6});
         end
      end

      fId = fopen(reportFilePathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while creating file : %s\n', reportFilePathName);
         return
      end

      fprintf(fId, 'Generator version number: %s\n', g_cogeoab_generateEasyOneArgoBgcVersion);
      fprintf(fId, 'Run date: %s\n', g_cogeoab_nowUtcStr);
      fprintf(fId, 'Run time: %s\n', duration);
      fprintf(fId, 'Number of input Argo single-cycle BGC synthetic files: %d\n', nbInputFiles);
      % fprintf(fId, 'Number of input profiles: %d\n', nbInputProfiles);
      fprintf(fId, 'Number of output CSV files in the %s dataset: %d\n\n', datasetName, nbOutputFiles);

      fprintf(fId, '%s\n', exludedProfStr{:});

      fclose(fId);
   end
end

return

% ------------------------------------------------------------------------------
% Add institution to data center code.
%
% SYNTAX :
%  [o_extendedDataCenter] = get_extended_data_center(a_dataCentre)
%
% INPUT PARAMETERS :
%   a_dataCentre : data centre code
%
% OUTPUT PARAMETERS :
%   o_extendedDataCenter : extended data centre
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/21/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_extendedDataCenter] = get_extended_data_center(a_dataCentre)

o_extendedDataCenter = '';


switch (a_dataCentre)

   case 'AO'
      o_extendedDataCenter = 'AOML, USA';
   case 'BO'
      o_extendedDataCenter = 'BODC, United Kingdom';
   case 'CI'
      o_extendedDataCenter = 'Institute of Ocean Sciences, Canada';
   case 'CS'
      o_extendedDataCenter = 'CSIRO, Australia';
   case 'EA'
      o_extendedDataCenter = 'Euro-Argo, Europe';
   case 'GE'
      o_extendedDataCenter = 'BSH, Germany';
   case 'GT'
      o_extendedDataCenter = 'GTS : used for data coming from WMO GTS network';
   case 'HZ'
      o_extendedDataCenter = 'CSIO, China Second Institute of Oceanography';
   case 'IF'
      o_extendedDataCenter = 'Ifremer, France';
   case 'IN'
      o_extendedDataCenter = 'INCOIS, India';
   case 'JA'
      o_extendedDataCenter = 'JMA, Japan';
   case 'JM'
      o_extendedDataCenter = 'Jamstec, Japan';
   case 'KM'
      o_extendedDataCenter = 'KMA, Korea';
   case 'KO'
      o_extendedDataCenter = 'KIOST, Korea';
   case 'LV'
      o_extendedDataCenter = 'Laboratoire OcC)anographique de Villefranche, Sorbonne University';
   case 'MB'
      o_extendedDataCenter = 'MBARI, USA';
   case 'ME'
      o_extendedDataCenter = 'MEDS, Canada';
   case 'NA'
      o_extendedDataCenter = 'NAVO, USA';
   case 'NM'
      o_extendedDataCenter = 'NMDIS, China';
   case 'PL'
      o_extendedDataCenter = 'IOPAN, Institute of Oceanology Polish Academy of Science';
   case 'PM'
      o_extendedDataCenter = 'PMEL, USA';
   case 'RU'
      o_extendedDataCenter = 'Russia';
   case 'SI'
      o_extendedDataCenter = 'SIO, Scripps, USA';
   case 'SP'
      o_extendedDataCenter = 'Spain';
   case 'UW'
      o_extendedDataCenter = 'University of Washington, USA';
   case 'VL'
      o_extendedDataCenter = 'Far Eastern Regional Hydrometeorological Research Institute of Vladivostock, Russia';
   case 'WH'
      o_extendedDataCenter = 'Woods Hole Oceanographic Institution, USA';

   otherwise
      fprintf('ERROR: ''%s'' data centre is not managed in get_extended_data_center\n', a_dataCentre);
      return
end

o_extendedDataCenter = [a_dataCentre ' (' o_extendedDataCenter ')'];

return

% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------
% the following code is duplicated from Coriolis processing chain so that this
% tool can be used as a standalone function
% ------------------------------------------------------------------------------
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)

   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end

   try

      % retrieve the list of variables that are present in the file
      varFlagList = vars_are_present_dec_argo(fCdf, a_wantedVars);

      % retrieve variables from NetCDF file
      for idVar = 1:length(a_wantedVars)
         if (varFlagList(idVar) == 1)
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, a_wantedVars{idVar}));
            o_ncData = [o_ncData {a_wantedVars{idVar}} {varValue}];
         else
            %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
            %             varName, a_ncPathFileName);
            o_ncData = [o_ncData {a_wantedVars{idVar}} {''}];
         end

      end

      netcdf.close(fCdf);

   catch MException
      netcdf.close(fCdf);
      rethrow(MException)
   end
end

return

% ------------------------------------------------------------------------------
% Check if a given list of variables are present in a NetCDF file.
%
% SYNTAX :
%  [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)
%
% INPUT PARAMETERS :
%   a_ncId        : NetCDF file Id
%   a_varNameList : list of variable names
%
% OUTPUT PARAMETERS :
%   o_varFlagList : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/06/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)

o_varFlagList = ones(size(a_varNameList));

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

valList = cell(nbVars, 1);
for idVar = 0:nbVars-1
   [valList{idVar+1}, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
end

notPresentList = setdiff(a_varNameList, valList);
for idVar = 1:length(notPresentList)
   o_varFlagList(strcmp(notPresentList{idVar}, a_varNameList)) = 0;
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_infoMsg    : INFO messages
%   o_warningMsg : WARNING messages
%   o_errorMsg   : ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_infoMsg = [];
o_warningMsg = [];
o_errorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);

   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(line, 'INFO: ', length('INFO: ')))
            o_infoMsg = [o_infoMsg {line(length('INFO: ')+1:end)}];
         elseif (strncmp(line, 'WARNING: ', length('WARNING: ')))
            o_warningMsg = [o_warningMsg {line(length('WARNING: ')+1:end)}];
         elseif (strncmp(line, 'ERROR: ', length('ERROR: ')))
            o_errorMsg = [o_errorMsg {line(length('ERROR: ')+1:end)}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
end

return
